import { Application } from "https://deno.land/x/oak@v10.6.0/mod.ts";
import router from "./router.ts";

const port = 5000;

const app = new Application();

//router goes here
app.use(router.allowedMethods());
app.use(router.routes());


console.log(`Server Running on Port ${port}`);

await app.listen({ port });