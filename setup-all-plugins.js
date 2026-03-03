import { writeFileSync, readFileSync, existsSync, readdirSync, statSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const RELATIVE_DEPLOY_PATH = "../wp-deploy/deploy.js";
const pluginsDir = join(__dirname, "..");
console.log(`\n🔍 Scanning for plugins in: ${pluginsDir}`);

const items = readdirSync(pluginsDir);

items.forEach(item => {
    const fullPath = join(pluginsDir, item);

    // Only process directories and ignore hidden folders or backups
    if (item === 'wp-deploy') {
        return;
    }

    if (statSync(fullPath).isDirectory() && !item.startsWith('.') && !item.includes(' - Copy')) {
        const packageJsonPath = join(fullPath, 'package.json');
        let packageJson = {};

        if (existsSync(packageJsonPath)) {
            try {
                packageJson = JSON.parse(readFileSync(packageJsonPath, 'utf8'));
            } catch (e) {
                packageJson = {};
            }
        }

        // Initialize fields if they don't exist
        if (!packageJson.name) packageJson.name = item;
        if (!packageJson.version) packageJson.version = "1.0.0";
        if (!packageJson.type) packageJson.type = "module";
        if (!packageJson.scripts) packageJson.scripts = {};

        // Add the universal relative scripts
        packageJson.scripts.deploy = `node "${RELATIVE_DEPLOY_PATH}" production`;
        packageJson.scripts["deploy:staging"] = `node "${RELATIVE_DEPLOY_PATH}" staging`;

        writeFileSync(packageJsonPath, JSON.stringify(packageJson, null, 2));
        console.log(`✅ Set up: ${item}`);
    }
});

console.log(`\n🎉 DONE! All plugins now have "npm run deploy" capability on both Windows and Mac.`);
