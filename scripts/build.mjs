import { cp, rm, mkdir } from "node:fs/promises";
await rm("docs", {recursive:true,force:true});
await mkdir("docs", {recursive:true});
await cp("src/site","docs",{recursive:true});
console.log("Production build complete: docs/");
