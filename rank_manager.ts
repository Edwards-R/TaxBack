/* This is essentially a local representation of the rank structure
 * It is designed to prevent the server from querying the database repeatedly
 * over a small and very *very* infrequently piece of information
 * 
 * It is a singleton as it is mimicing a database connection yet needs to be
 * re-loaded *if* the rank structure changes
 * 
 */

import * as db from "./database.ts";
import Rank from "./rank.ts";

export default class RankManager{

    // Singleton Management
    private static instance: RankManager;

    // Variable Declaration
    private _ranks = new Map<number, Rank>(); // All ranks

    private _directSort: Array<number> = [];
    private _majorSort: Array<number> = [];
    
    // Singletons must have private constructors or they can be made, which is bad
    // Typescript doesn't support async constructors, which makes this pointless
    private constructor() {
    }

    // Singletons are accessed via here instead
    // This function is async as it requires a response from a database to complete
    
    /**
     * Fetches the Rank Manager. Use this instead of trying to make a new
     */
    public static async getInstance(): Promise<RankManager>{
        if (!RankManager.instance){
            RankManager.instance=new RankManager();
            // Move to initialisation

            // Fetch all ranks
            RankManager.instance._ranks = await RankManager.instance.FetchRanks(false);
            // Construct the sorted array of all ranks
            RankManager.instance._directSort = RankManager.instance.SortRanks(RankManager.instance._ranks, false);

            //Internal only fetching of major-only ranks and then sorting. Because the sort uses primary keys the resulting array
            // can be used on _ranks.

            //The second database fetch is required because of things like sub-species being potentially around and breaking things
            const major = await RankManager.instance.FetchRanks(true);
            RankManager.instance._majorSort = RankManager.instance.SortRanks(major, true);
        }
        return RankManager.instance;
    }

    // Get & Set
    public get ranks(): Map<number, Rank>{
        return this._ranks;
    }

    // Business logic comes here

    /**
     * Fetches the ranks from the database
     * @returns A map of the ranks present in the database
     */
    private async FetchRanks(major_only: boolean): Promise<Map<number, Rank>>{
        const ranks: Map<number, Rank> = new Map<number, Rank>(); // Map to store ranks
        //Need to pick whether all ranks or just major
        let queryText:string;
        if (major_only){
            queryText = "SELECT id, name, is_major, major_parent, direct_parent, display_name FROM taxonomy.rank WHERE is_major = TRUE";
        }else{
            queryText = "SELECT id, name, is_major, major_parent, direct_parent, display_name FROM taxonomy.rank"
        }
        const resp = await db.Query(queryText, {});
        resp.rows.forEach((row: unknown[]) => {
            // Make rank object (avoids double-casting)
            const r = new Rank(row[0] as number, row[1] as string, row[2] as boolean, row[3] as number, row[4] as number, row[5] as string);
            ranks.set(r.id as number, r);
        });
        return ranks;
    }


    /**
     * Finds the id of the foundation rank
     * @returns The id of the foundation rank
     */
    private FindFoundation(ranks: Map<number, Rank>): number {
        // Make a map to store the fails. false = not used, true = used
        const indexer: Map<number, boolean> = new Map<number, boolean>();
        // Populate the map with the ranks and default false
        ranks.forEach(rank => {
            indexer.set(rank.id, false);
        });
        // Now loop over _ranks again and set the corresponding DIRECT PARENT to true
        ranks.forEach(rank => {
            indexer.set(rank.direct_parent, true);
        });
        // The foundation element will be the only element with 'false'
        for (const [key, value] of indexer){
            if (!value){
                return key;
            }
        }
        // If it reaches this point then it couldn't find a foundation, which means the whole thing is bricked
        // At this point it's a manual 'go into the database and fix it' job
        throw new Error("No foundation could be found, rank structure compromised");
    }

    /*
    * Need a function for based sorting and one for major based sorting
    * Since the only thing that matters to the sorting is itself, can't rely on directional/numerical sorting
    * methods. It's not the best, but there's no way right now for the system to figure out of it has been 
    * passed a major-only map or direct map. The one saving grace is that this is an internal function and
    * no-one else has to see it.
    */

    /**
     * Creates an array of map indexes sorted in ascending order
     * This WILL fail if told to sort a direct parentage map by major parent
     * @param ranks The map of ranks to sort
     * @param major True = sort by major, false = sort by direct
     * @returns A map of the provided ranks sorted by 
     */
    private SortRanks(ranks: Map<number, Rank>, major: boolean): number[]{
        // Make the recipient
        const sortedRanks: Array<number> = new Array<number>(); //Not *really* an array I think, but works as one
        // Find the foundation
        const foundation: number = this.FindFoundation(ranks);
        // Fetch the foundation
        let r: Rank = ranks.get(foundation)!; //Assert non-null
        // Add the foundation
        sortedRanks.push(r.id);
        
        // While the id is not equal to the specified parent rank, i.e. the capstone has not been reached
        while (r.id != r.SelectParent(major)){
            r=ranks.get(r.SelectParent(major))!;
            // Place the set command AFTER the select so that the capstone is added
            // If you set before moving the 'pointer' along via the select, the capstone will be ommitted since the while is false
            sortedRanks.push(r.id);
        }
        return sortedRanks;
    }

    /**
     * Find the position of a given rank in the sorted array of all ranks
     * @param rankID The id of the rank to find the position of
     * @returns The position of the rank in the sorted array
     */
    public FindRankPlace(rankID: number): number{
        let i=0; // Arrays are 0-indexed
        for (const value of RankManager.instance._directSort){
            if (value==rankID){
                return i;
            }
            i++;
        }
        throw ("Rank ID not found in loaded ranks");
    }

    /**
     * Provides the Rank object that is the direct child of the provided rank ID
     * Emulates a database query and should be considered part of the data layer
     * 
     * @param rankID The rank ID to find the direct child rank of
     * @returns The child Rank
     */
    public FindChild(rankID: number): Rank{
        //Find placement of rankid
        const placement = RankManager.instance.FindRankPlace(rankID);
        if (placement == 0) {
            throw new RangeError("Cannot find child of foundation rank");
        }else{
            // Get the rank (from _ranks) which is before this one in the fully sorted array
            return RankManager.instance._ranks.get(RankManager.instance._directSort[placement-1])!;
        }
    }
}