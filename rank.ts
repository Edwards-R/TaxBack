import * as db from "./database.ts";
import Understanding from "./understanding.ts";
import RankManager from "./rank_manager.ts";

export default class Rank{
    private _id: number;
    private _name: string;
    private _is_major: boolean;
    private _major_parent: number;
    private _direct_parent: number;
    private _display_name: string;

    //Internalise the query string so that it doesn't get garbled
    private _queryString: string;
    private _queryTypeString: string;

    constructor(id: number, name: string, is_major: boolean, major_parent: number, direct_parent: number, display_name: string){
        this._id = id;
        this._name = name;
        this._is_major = is_major;
        this._major_parent = major_parent;
        this._direct_parent = direct_parent;
        this._display_name = display_name;

        this._queryString = "SELECT id, name, author, year, parent, current FROM taxonomy.\"" + this._name + "\" WHERE ";
        this._queryTypeString = "SELECT id, name, author, year, parent, current FROM taxonomy.\"" + this._name + "_type\" WHERE ";
    }

    get id(): number{
        return this._id;
    }

    get name(): string{
        return this._name;
    }

    get is_major(): boolean{
        return this._is_major;
    }

    get major_parent(): number{
        return this._major_parent;
    }

    get direct_parent(): number{
        return this._direct_parent;
    }

    get display_name(): string{
        return this._display_name;
    }

    get queryString(): string{
        return this._queryString;
    }

    get queryTypeString(): string{
        return this._queryTypeString;
    }

    /**
     * Search the database for understandings where the name at least partially matches the provided string
     * @param name The search string for name
     * @returns An array of Understandings which at least partially match the provided string
     */
    public async SelectByName(name: string): Promise<Understanding[]>{
        const queryText = this.queryString + "name ilike $nameWrap";
        const nameWrap = "%"+name+"%"; //Wrap the name with % characters for pattern matching
        const result = await db.Query(queryText, {nameWrap});
        //Set up the array
        const understandings: Understanding[] = new Array(result.rowCount);
        result.rows.forEach(row => {
            understandings.push(
                new Understanding(
                    this,
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

    public async SelectByID(id: number): Promise<Understanding>{
        const queryText = this.queryString + "id = $id";
        const result = await db.Query(queryText, {id});

        return new Understanding(
            this,
            result.rows[0][0] as number,
            result.rows[0][1] as string,
            result.rows[0][2] as string,
            result.rows[0][3] as number,
            result.rows[0][4] as number,
            result.rows[0][5] as number,
        )
    }

    /**
     * Function which returns either the major or direct parent.
     * Designed specifically for use in sorting ranks based on major or
     * direct parentage.
     * @param major true = major parent, false = direct parent
     * @returns The ID of the specified parent
     */
    public SelectParent(major: boolean): number{
        if (major){
            return this._major_parent;
        }else{
            return this._direct_parent
        }
    }


    /**
     * Fetch the child rank of this rank
     * @returns The child Rank object
     */
    public async FetchChild(): Promise<Rank>{
        // Access the rank manager
        const rm: RankManager = await RankManager.getInstance();
        // Find the index of the current 
        return rm.FindChild(this._id);
    }
}