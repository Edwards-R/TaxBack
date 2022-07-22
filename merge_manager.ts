/*
 * This class is responsible for overseeing a merger of multiple understandings
 * Each major 'action' has its own manager, e.g. merge, split etc
 * These are the rules which must be obeyed:
 * 
 * 1. The merge must happen within a singular taxonomic tier
 * 
 * Also remember that this is an exposed service and should accept keys NOT items
 * Since this is accepting keys, it needs to do some validation of the commands as well
*/

import RankManager from "./rank_manager.ts";
import Rank from "./rank.ts";
import Understanding from "./understanding.ts";
import TypeManager from "./type_manager.ts";
import Type from "./type.ts";

export default class MergeManager{
    
    // Some variables have to be set to null at the start because Typescript demands setting, but can't use async in constructors
    private _rank: Rank | null = null;
    private _inputs: Array<Understanding> =  new Array<Understanding>();
    private _outputName = "";
    private _author = "";
    private _year = 0;
    private _type: Type | null = null;

    // No Async constructors = can't use constructor in async app
    public constructor (){
    }

    public static async init(rankID: number, inputs: Array<number>, outputName: string, author: string, year: number, typeID: number){
        const me = new MergeManager();
        try{
            me._rank = await me.FetchRank(rankID);
            me._inputs = await me.FetchInputs(inputs)
            me._outputName = outputName;
            me._author = author;
            me._year = me.CheckYear(year);
            me._type = await me.FetchType(typeID);
        }catch (error) {
            // Throw the error up the chain? Might just remove the try and have it be caught on the calling side
            throw error;
        }
    }

    // Validation of inputs. This is async so can't go in constructor

    /**
     * Attempts to find the provided rank and load it into the class
     * Will throw an error if the rank cannot be found
     * @param rankID The ID of the rank to find
     * @returns The fetched Rank
     */
    private async FetchRank(rankID: number): Promise<Rank>{
        const rm = await RankManager.getInstance();
        const rank: Rank|undefined = rm.ranks.get(rankID);
        if (rank == undefined) {
            throw ("Rank could not be found");
        }else{
            return rank!;
        }
    }

    /**
     * Attempts to find each Understanding from the provided IDs. Will throw an error if any cannot be found
     * Specifically does not make a claim on whether the provided IDs *should* be used, that is the responsibility
     * of the human.
     * @param inputs An array of the input IDs
     * @returns An array of Understandings
     */
    private async FetchInputs(inputs: Array<number>): Promise<Array<Understanding>>{
        const processed: Array<Understanding> = new Array<Understanding>();
        for (const input of inputs){
            const process: Understanding | undefined = await this._rank?.SelectByID(input);

            if (process == undefined) {
                throw ("Understanding could not be found");
            }else{
                processed.push(process);
            }
        }
        return processed;
    }

    /**
     * Checks to see if the year is valid
     * @param year The year to check
     * @returns The checked year
     */
    private CheckYear(year: number): number {
        // (fairly arbitrary) cut off for the lower bound of the date, as well as not allowing future dates
        if (year <=1600 || year >= new Date().getFullYear()){
            return year;
        }else{
            throw ("Supplied date out of range (1600 to now)");
        }
    }

    /**
     * Attempts to find the specified Type. Remember that one and only one Type should ever be assigned to
     * anything which is not an aggregate. Will throw an error if the type cannot be found
     * @param typeID The ID of the type to find
     * @returns 
     */
    private async FetchType(typeID: number): Promise<Type>{
        const tm: TypeManager = TypeManager.getInstance();
        try{
            const value: Type = await tm.SelectById(typeID);
            return value;
        }catch{
            throw ("The provided type could not be found");
        }
    }

    // Performing the creation
    public async DoSplit(){
        
    }
}