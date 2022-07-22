import { Router } from "https://deno.land/x/oak@v10.6.0/mod.ts";

// Imports for testing
import * as db from "./database.ts";
import RankManager from "./rank_manager.ts";

const router = new Router();

router.get("/", (ctx) => {
    ctx.response.body = "This was a get request\n";
});

router.put("/", (ctx) => {
    ctx.response.body = "This was a put request\n";
})

router.post("/", (ctx) => {
    ctx.response.body = "This was a post request\n";
})

router.get("/query", (ctx) => {
    try{
        const resp = db.Query("SELECT * FROM taxonomy.species LIMIT 10", {});
        console.log(resp);
        resp.then(function(result){
            console.log(result);
        })
        ctx.response.body= "Test executed";
    }catch (err) {
        console.log("Error:", err)
    }
})

router.get("/test", async (ctx) => {
    const rm = await RankManager.getInstance();
    const ranks = rm.ranks;
    const useRank = ranks.get(4)!;
    const results = await useRank.SelectByName("Bombus");
    const children = await results[1].FetchDirectChildren(true);
    for (const useable of children){
        console.log(useable.name);
    }
    ctx.response.body = "test";
})


export default router;