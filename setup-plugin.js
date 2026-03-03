import { writeFileSync, readFileSync, existsSync } from 'fs';
import { join, basename } from 'path';
import { fileURLToPath } from 'url';

const pluginDir = process.cwd();
const pluginName = basename(pluginDir);

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

// Use a sibling wp-deploy repo so commands work from any plugin in this checkout layout.
packageJson.scripts.deploy = 'node "../wp-deploy/deploy.js" production';
packageJson.scripts["deploy:staging"] = 'node "../wp-deploy/deploy.js" staging';

writeFileSync(packageJsonPath, JSON.stringify(packageJson, null, 2));

console.log(`✅ Success! Added "npm run deploy" to ${pluginName}/package.json`);
console.log(`🚀 You can now run "npm run deploy" to go live, or "npm run deploy:staging" for test.`);
