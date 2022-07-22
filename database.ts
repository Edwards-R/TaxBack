import "https://deno.land/x/dotenv@v3.2.0/load.ts"; // Load the .env file into deno's env
import { Pool } from "https://deno.land/x/postgres@v0.16.0/mod.ts";

const pool = new Pool({
    user: Deno.env.get("DB_USER"),
    hostname: Deno.env.get("HOSTNAME"),
    database: Deno.env.get("DATABASE"),
    port: Deno.env.get("DB_PORT"),
    password: Deno.env.get("DB_PASSWORD")
},4, true);

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