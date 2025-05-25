#!/bin/bash

# 定義專案根目錄
PROJECT_ROOT="/opt/napp-gemini"

echo "正在建立 NAPP 專案目錄結構 (Python 後端版) 於 $PROJECT_ROOT..."

# 1. 建立根目錄
sudo mkdir -p "$PROJECT_ROOT"
if [ $? -ne 0 ]; then
    echo "錯誤：無法建立或存取 $PROJECT_ROOT。請檢查權限。"
    exit 1
fi
echo "已建立：$PROJECT_ROOT"

# 進入專案根目錄
cd "$PROJECT_ROOT"

# 2. 建立後端 (Python Flask) 目錄結構與檔案
echo "建立後端目錄及檔案..."
sudo mkdir -p backend/{routes,utils}
sudo touch backend/app.py            # 主應用程式檔案
sudo touch backend/config.py         # 配置檔案
sudo touch backend/models.py         # 資料庫模型檔案
sudo touch backend/requirements.txt  # Python 依賴清單
sudo touch backend/routes/auth.py    # 認證路由
sudo touch backend/routes/users.py   # 使用者管理路由
sudo touch backend/utils/auth_decorators.py # 認證裝飾器
sudo touch backend/utils/email_service.py   # 郵件服務
echo "已建立：backend/{routes,utils}, app.py, config.py, models.py, requirements.txt, routes/{auth.py,users.py}, utils/{auth_decorators.py,email_service.py}"

# 3. 建立前端 (Flutter Web) 目錄結構與檔案 (與先前相同，保持一致性)
echo "建立前端目錄及檔案..."
sudo mkdir -p frontend/{lib/api,lib/providers,lib/screens,lib/widgets,web}
sudo touch frontend/pubspec.yaml
sudo touch frontend/lib/main.dart
sudo touch frontend/lib/api/api_service.dart
sudo touch frontend/lib/providers/auth_provider.dart
sudo touch frontend/lib/screens/login_screen.dart
sudo touch frontend/lib/screens/home_screen.dart
sudo touch frontend/lib/screens/user_management_screen.dart
sudo touch frontend/lib/screens/change_password_screen.dart
sudo touch frontend/lib/screens/forgot_password_screen.dart
sudo touch frontend/lib/screens/reset_password_screen.dart
sudo touch frontend/lib/widgets/custom_alert_dialog.dart
echo "已建立：frontend/{lib/api,lib/providers,lib/screens,lib/widgets,web}, frontend/pubspec.yaml, frontend/lib/main.dart, ...等 Flutter 相關檔案"

# 4. 建立資料庫目錄結構與檔案
echo "建立資料庫目錄..."
sudo mkdir -p database
sudo touch database/init.sql
echo "已建立：database/, database/init.sql"

# 5. 建立 Docker 目錄結構與檔案
echo "建立 Docker 目錄..."
sudo mkdir -p docker/{backend,database}
sudo touch docker/backend/Dockerfile        # Python 後端的 Dockerfile
sudo touch docker/database/Dockerfile       # 資料庫的 Dockerfile
sudo touch docker/docker-compose.yml        # Docker Compose 檔案
echo "已建立：docker/{backend,database}, Dockerfile, docker-compose.yml"

# 6. 建立根目錄下的通用檔案
echo "建立根目錄通用檔案..."
sudo touch README.md
sudo touch .gitignore                       # Git 忽略檔案
sudo touch .env                             # 集中式環境變數檔案
echo "已建立：README.md, .gitignore, .env"

echo ""
echo "NAPP 專案目錄結構 (Python 後端版) 建立完成！"
echo "請記得將實際的程式碼內容填入這些檔案和目錄中。"
echo "現在您可以進入 $PROJECT_ROOT 並開始 Git 操作了。"
