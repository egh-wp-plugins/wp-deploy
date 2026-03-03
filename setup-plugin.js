import { writeFileSync, readFileSync, existsSync } from 'fs';
import { join, basename, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const pluginDir = process.cwd();
const pluginName = basename(pluginDir);
const deployJsPath = join(__dirname, 'deploy.js');

console.log(`\n🔧 Setting up deployment for plugin: ${pluginName}`);

const packageJsonPath = join(pluginDir, 'package.json');
let packageJson = {};

if (existsSync(packageJsonPath)) {
    packageJson = JSON.parse(readFileSync(packageJsonPath, 'utf8'));
} else {
    packageJson = {
        name: pluginName,
        version: "1.0.0",
        type: "module"
    };
}

if (!packageJson.scripts) packageJson.scripts = {};

// Add the deploy script pointing to the central deploy.js
packageJson.scripts.deploy = `node "${deployJsPath}" production`;
packageJson.scripts["deploy:staging"] = `node "${deployJsPath}" staging`;

writeFileSync(packageJsonPath, JSON.stringify(packageJson, null, 2));

console.log(`✅ Success! Added "npm run deploy" to ${pluginName}/package.json`);
console.log(`🚀 You can now run "npm run deploy" to go live, or "npm run deploy:staging" for test.`);
