import "https://deno.land/x/dotenv@v3.2.0/load.ts"; // Load the .env file into deno's env
import { Pool } from "https://deno.land/x/postgres@v0.16.0/mod.ts";

const pool = new Pool({
    user: Deno.env.get("DB_USER"),
    hostname: Deno.env.get("HOSTNAME"),
    database: Deno.env.get("DATABASE"),
    port: Deno.env.get("DB_PORT"),
    password: Deno.env.get("DB_PASSWORD")
},4, true);

/**
 * A wrapped open/query/close function for the 'local' database. Specifically does not have the
 * ability to query type information
 * @param query The query text
 * @param args The arguments for the query. Should be in format 'argName: argValue'
 * @returns The promise for the query result in an array. See docs for deno postgres for more information
 */
// deno-lint-ignore ban-types
export async function Query(query: string, args: {} |undefined){
    const client = await pool.connect();
    let result;
    try{
        result = await client.queryArray(query, args);
    }
    finally {
        client.release();
    }
    return result;
}