import { execSync } from 'child_process';
import { platform } from 'os';
import { dirname, join, basename } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

let pluginName = process.argv[2];
let env = process.argv[3] || 'staging';
let specificFiles = process.argv.slice(4);

if (pluginName === 'staging' || pluginName === 'production' || !pluginName) {
    if (pluginName === 'staging' || pluginName === 'production') {
        env = pluginName;
        specificFiles = process.argv.slice(3);
    } else {
        specificFiles = process.argv.slice(2);
    }
    pluginName = basename(process.cwd());
    console.log(`ℹ️ No plugin specified, using current directory: ${pluginName}`);
}

const isWindows = platform() === 'win32';

if (specificFiles.length > 0) {
    console.log(`\n📦 Deploying specific files for plugin "${pluginName}" to ${env}: ${specificFiles.join(', ')}`);
} else {
    console.log(`\n📦 Deploying ALL files for plugin "${pluginName}" to ${env}...`);
}

const scriptPath = isWindows
    ? join(__dirname, 'deploy.ps1')
    : join(__dirname, 'deploy.sh');

const filesParam = specificFiles.join(',');

const command = isWindows
    ? `powershell -ExecutionPolicy Bypass -File "${scriptPath}" -PluginName "${pluginName}" -EnvName "${env}" -SpecificFiles "${filesParam}"`
    : `chmod +x "${scriptPath}" && "${scriptPath}" "${pluginName}" "${env}" "${filesParam}"`;

try {
    execSync(command, {
        stdio: 'inherit',
        cwd: __dirname
    });
} catch (error) {
    console.error(`\n❌ Deployment of ${pluginName} failed.`);
    process.exit(1);
}
