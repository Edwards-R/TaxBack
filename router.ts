import { Router } from "https://deno.land/x/oak@v10.6.0/mod.ts";
import * as db from "./database.ts";

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
        const resp = db.Query("SELECT * FROM species WHERE higherid = $higherid LIMIT 10", {higherid: 104});
        console.log(resp);
        resp.then(function(result){
            console.log(result);
        })
        ctx.response.body= "Test executed";
    }catch (err) {
        console.log("Error:", err)
    }
})


export default router;