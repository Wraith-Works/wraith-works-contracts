const fs = require("fs");
const packageJson = require("../package.json");

async function main() {
    if (!fs.existsSync("./publish")) {
        console.error("Run `yarn prepackage` before `yarn remap`");
        process.exit(1);
    }

    const newPackageJson = {
        name: packageJson.name,
        version: packageJson.version,
        description: packageJson.description,
        repository: packageJson.repository,
        author: packageJson.author,
        license: packageJson.license,
        files: ["**/*.sol", "/build/contracts/*.json"],
        dependencies: packageJson.dependencies,
    };
    fs.writeFileSync("./publish/package.json", JSON.stringify(newPackageJson, null, 4));
}

main()
    .then(() => process.exit())
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
