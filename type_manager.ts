/**
 * This class is a database access point.
 * Because ranks are not generic but rather specific to the foundation rank,
 * the ability use and access ranks cannot be placed in the generic 'Understanding'
 * class.
 * 
 * At least, not without making exceptions the normality rather than exception.
 * Calling 'get types' on a non-foundation would be an exception, which would
 * be the rule rather than the exception as there is only one foundation class
 * 
 * The other option is to extend the 'Understanding' class to have a 
 * 'foundation understanding' class, but then rank manager would have to track
 * which rank was the foundation. It could do that, but it gets a bit 'eh, would
 * this actually work?'. Placing type management into a separate class allows
 * development to progress and yet allows for potential future development to
 * unify things.
 * 
 * The manager also fits with the creation of new types, which:
 * a) mirrors rank and understanding management
 * b) keep making types SUPER specific, which is good because types should
 * not be conjured out of nothing. Making a new type is a BIG DEAL.
 */

 import * as db from "./database.ts";
 import Type from "./type.ts";
 import Understanding from "./understanding.ts";
 import RankManager from "./rank_manager.ts";
 import Rank from "./rank.ts";


 export default class TypeManager{
    // Singleton Management
    private static instance: TypeManager;

    //Singletons get a private constructor
    private constructor() {
        
    }

    public static getInstance(): TypeManager{
        if (!TypeManager.instance){
            TypeManager.instance=new TypeManager();
        }
        return TypeManager.instance;
    }

    public async SelectById(id: number): Promise<Type>{
        const queryText = "SELECT id, full_name, author, year FROM taxonomy.type WHERE id=$id";
        const result = await db.Query(queryText, {id});
        return new Type(
            result.rows[0][0] as number,
            result.rows[0][1] as string,
            result.rows[0][2] as string,
            result.rows[0][3] as number,
        )
    }

    /**
     * Creates a new type entry. Intended to store a direct copy of the physical label of the type specimen
     * 
     * @param name The full name of the type specimen, as per the physical label
     * @param author The author of the type, as per the physical label
     * @param year The year of declaration of the type e.g. 2022, as per the physical label
     */
    public async CreateType(name: string, author: string, year: number){
        const queryText = "INSERT INTO taxonomy.type (full_name, author, year) VALUES ($name, $author, $year)";
        const result = await db.Query(queryText, {name, author, year});
        console.log(result);
    }

    // This should really go in a different place as it references the non-type storage rather than the type storage. Maybe
    // attach it to the Understanding?

    /**
     * Creates a link between an understanding and a type
     * @param understanding The understanding to assign the type to
     * @param type The type to assign to the understanding
     */
    public async AssignType(understanding: Understanding, type: Type) {
        const rm = await RankManager.getInstance();
        const rank: Rank|undefined = rm.ranks.get(understanding.rank.id);

        const queryText = "INSERT INTO taxonomy."+rank!.name+"_type (species, type) VALUES ($species, $type)";
        //Typescript is not letting me access this getter from inside an object declaration, so expose it directly
        const understanding_id: number = understanding.id;
        const type_id: number = type.id;
        const result = await db.Query(queryText, {understanding_id, type_id});
        console.log(result);
    }
 }