# WordPress Plugin Deployment System (Cross-Platform)

This folder contains a universal deployment engine for WordPress plugins. It is designed to work seamlessly on both **MacOS** and **Windows**.

## 🚀 Quick Start for AI Assistants

If you are an AI assisting the user on this machine, follow these rules:

1.  **Context**: The user has their plugins managed locally inside `../` relative to `wp-deploy`.
2.  **Deployment Engine**: Always use `deploy.js` located in this folder. It handles OS detection (Windows vs Mac) and environment routing, and specific file transfers.
3.  **Current Plugin Logic**: If the user is inside a plugin folder, you can deploy it by specifying its folder name, environment, and specific files to upload.

### Deployment Commands

#### On MacOS
*   **Live**: `node "[PATH_TO_WP_DEPLOY]/deploy.js" [PLUGIN_NAME] production [FILE_1] [FILE_2]`
*   **Staging**: `node "[PATH_TO_WP_DEPLOY]/deploy.js" [PLUGIN_NAME] staging [FILE_1] [FILE_2]`

#### On Windows (PowerShell)
*   **Live**: `node "[PATH_TO_WP_DEPLOY]\deploy.js" [PLUGIN_NAME] production [FILE_1] [FILE_2]`
*   **Staging**: `node "[PATH_TO_WP_DEPLOY]\deploy.js" [PLUGIN_NAME] staging [FILE_1] [FILE_2]`

*Note: the `[FILE_1]` parameters are optional. If not provided, it deploys the entire plugin folder (though that is slower).*

### Using package.json scripts (npm run deploy)

If your plugin has an `npm run deploy` script set up in its `package.json` (like `egh-about-me`), you can also upload a single file (or multiple) by passing arguments via npm's `--` flag:

```bash
# Deploys a single file (e.g., package.json)
npm run deploy -- package.json

# Deploys multiple specific files
npm run deploy -- file1.php file2.css
```

---

## 🛠 Setup & Global Shortcuts

### MacOS Setup
The user has aliases in `~/.zshrc`:
*   `wp-deploy` -> Deploys current folder to Live.
*   `wp-test` -> Deploys current folder to Staging.

*Update your alias function to support extra arguments (e.g. `wp-deploy file.php`).*

### Windows Setup (Required on new machine)
Run these in PowerShell to enable the same shortcuts and support file arguments:
```powershell
function wp-deploy { 
    $currentName = Split-Path -Leaf $PWD
    node "C:\Users\NW USER\Desktop\gh-projects\wp-plugins\wp-deploy\deploy.js" $currentName production $args
}
function wp-test { 
    $currentName = Split-Path -Leaf $PWD
    node "C:\Users\NW USER\Desktop\gh-projects\wp-plugins\wp-deploy\deploy.js" $currentName staging $args
}
```

---

## 🐙 GitHub Organization (egh-wp-plugins)

All plugins in this ecosystem are hosted under the [egh-wp-plugins](https://github.com/egh-wp-plugins) organization.

### Pushing to GitHub
To push a plugin to the organization, use the following flow:
1.  **Initialize Git**: `git init`
2.  **Add Files**: `git add .` (ensure `.gitignore` is present)
3.  **Commit**: `git commit -m "initial commit"`
4.  **Create Remote**: `gh repo create egh-wp-plugins/[PLUGIN_NAME] --public --source=. --remote=origin`
5.  **Push**: `git push -u origin main`

### Pulling Updates
To pull the latest version of a plugin:
```bash
git pull origin main
```

---

## 📂 System Architecture
...
