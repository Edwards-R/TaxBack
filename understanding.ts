import Rank from "./rank.ts";
import * as db from "./database.ts";

export default class Understanding{
    
    private _rank: Rank;
    private _id: number;
    private _name: string;
    private _author: string;
    private _year: number;
    private _parent: number;
    private _current: number;
    /*
     * Types are a 'not always needed' thing, but since they can't change then they can be cached once pulled
     * from the database. It's a 'lazy initialisation' - they are fetched when required rather than at
     * construction. Most queries won't care about the types, so 'lazy' querying will save a ton of database time
     * 
     * These are SPECIFICALLY typeIDs, not types, to avoid a potentially expensive call to an external system.
     * Calling the Type database is the realm of the type manager and nothing else.
    */
    private _typeIDs: Array<number> | undefined;
    
    constructor(rank: Rank, id: number, name: string, author: string, year: number, parent: number, current: number){
        this._rank=rank;
        this._id = id;
        this._name = name;
        this._author = author;
        this._year = year;
        this._parent = parent;
        this._current = current;
    }

    get rank(): Rank{
        return this._rank;
    }

    get id(): number{
        return this._id;
    }
    
    get name(): string{
        return this._name;
    }

    get author(): string{
        return this._author;
    }

    get year(): number{
        return this._year;
    }

    get parent(): number{
        return this._parent;
    }

    get current(): number{
        return this._current;
    }

    /* Fetch will do type conversions */

    /**
     * Fetches the direct children of this Understanding
     * @returns An array of Understandings
     */
    public async FetchDirectChildren(currentOnly: boolean): Promise<Understanding[]>{
        const childRank = await this._rank.FetchChild();
        let queryText = childRank.queryString + "parent = $useID"; //use the query string from the rank to ensure continuity

        // Implement current-only if required
        if (currentOnly){
            queryText += " AND id = current";
        }

        const useID = this.id; // Typescript and queries and not letting me use this.id so... IDK
        const result = await db.Query(queryText, {useID});
        const understandings: Understanding[] = new Array<Understanding>();
        result.rows.forEach(row => {
            understandings.push(
                new Understanding(
                    childRank,
                    row[0] as number,
                    row[1] as string,
                    row[2] as string,
                    row[3] as number,
                    row[4] as number,
                    row[5] as number,
                )
            )
        });
        return understandings;
    }

    public async UpdateCurrent(value: number){

        // Try/catch used to ensure synchrony between value and database
        // Database responsible for ensuring that foreign key exists

        const id = this.id; // That annoying 'no this' problem
        const queryText = "UPDATE " + this._rank.name + " SET current = $value WHERE id = $id";
        try {
            await db.Query(queryText, {
                    value,
                    id,
                }
            );
            this._current = value;
        }catch (e){
            console.log(e);
        }
    }

    /**
     * Fetches the associated type ID(s) of the understanding
     * Specifically DOES NOT fetch the types, as fetching types is intended to be
     * a call to a separate, remote, server and therefore slower. It's also rarely
     * needed, whilst knowing if an understanding is considered an aggregate is
     * far more common
     * @returns An array of the IDs of the known types
     */
    private async FetchTypeIDs(): Promise<number[]>{
        // The old 'can't use this'
        const useID = this._id;
        const queryText = this._rank.queryTypeString + this._rank.name + " = {id}";
        const result = await db.Query(queryText, {useID});
        const types: number[] = new Array<number>();
        result.rows.forEach(row => {
            types.push(row[0] as number);
        });
        return types;
    }

    /**
     * A lazy getter for Types. Cannot be a 'get' as Typescript does not support async get
     * @returns An array of the IDs of the known types
     */
    public async TypeIDs(): Promise<number[]>{
        if (this._typeIDs == undefined){
            this._typeIDs = await this.FetchTypeIDs();
        }
        return this._typeIDs;
    }

    /**
     * A hard-coded logical evaluation of whether the understanding is an aggregate i.e. the
     * Understanding contains more tha one direct type association.
     * @returns True if the understanding is an aggregate (regardless of name)
     */
    public async IsAggregate(): Promise<boolean>{
        if (await this.TypeIDs.length > 1){
            return true;
        }else{
            return false;
        }
    }
}