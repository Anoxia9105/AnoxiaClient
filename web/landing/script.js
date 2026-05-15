/**
 * Anoxia IM 官网脚本
 * 负责版本信息获取、交互效果和动画处理
 */

const API_URL = 'https://chat.anoxia.cn/api/app/update/public/latest-links';

/**
 * 平台配置映射
 */
const platformConfig = {
    windows: {
        versionEl: 'windows-version',
        notesEl: 'windows-notes',
        downloadEl: 'windows-download',
        ext: '.exe'
    },
    macos: {
        versionEl: 'macos-version',
        notesEl: 'macos-notes',
        downloadEl: 'macos-download',
        ext: '.dmg'
    },
    android: {
        versionEl: 'android-version',
        notesEl: 'android-notes',
        downloadEl: 'android-download',
        ext: '.apk'
    },
    ios: {
        versionEl: 'ios-version',
        notesEl: 'ios-notes',
        downloadEl: 'ios-download',
        ext: ''
    },
    linux: {
        versionEl: null,
        notesEl: null,
        downloadEl: null,
        ext: ''
    }
};

/**
 * 获取最新版本信息
 */
async function fetchLatestVersions() {
    try {
        const response = await fetch(API_URL);
        const result = await response.json();
        
        if (result.code === 200 && result.data && result.data.items) {
            updateVersionDisplay(result.data.items);
        } else {
            showVersionError();
        }
    } catch (error) {
        console.error('获取版本信息失败:', error);
        showVersionError();
    }
}

/**
 * 清理URL中的反引号
 * @param {string} url - 原始URL
 * @returns {string} 清理后的URL
 */
function cleanUrl(url) {
    if (!url) return null;
    return url.replace(/`/g, '').trim();
}

/**
 * 更新版本显示
 * @param {Array} items - 版本信息列表
 */
function updateVersionDisplay(items) {
    let latestVersion = null;
    
    items.forEach(item => {
        const config = platformConfig[item.clientType];
        if (!config) return;
        
        const versionEl = document.getElementById(config.versionEl);
        const notesEl = document.getElementById(config.notesEl);
        const downloadEl = document.getElementById(config.downloadEl);
        const card = document.querySelector(`.download-card[data-platform="${item.clientType}"]`);
        
        if (item.hasRelease && item.latestVersion) {
            if (versionEl) {
                versionEl.textContent = `v${item.latestVersion}`;
            }
            
            if (notesEl && item.releaseNotes) {
                notesEl.textContent = item.releaseNotes;
            }
            
            const cleanedUrl = cleanUrl(item.downloadUrl);
            if (downloadEl && cleanedUrl) {
                downloadEl.href = cleanedUrl;
                downloadEl.classList.remove('disabled');
            }
            
            if (!latestVersion || compareVersions(item.latestVersion, latestVersion) > 0) {
                latestVersion = item.latestVersion;
            }
        } else {
            if (versionEl) {
                versionEl.textContent = '即将推出';
            }
            if (notesEl) {
                notesEl.textContent = '敬请期待';
            }
            if (downloadEl) {
                downloadEl.classList.add('disabled');
                downloadEl.removeAttribute('href');
            }
            if (card) {
                card.classList.add('disabled');
            }
        }
    });
    
    const versionDisplay = document.getElementById('version-display');
    if (versionDisplay && latestVersion) {
        versionDisplay.textContent = `v${latestVersion}`;
    }
}

/**
 * 比较版本号
 * @param {string} v1 - 版本1
 * @param {string} v2 - 版本2
 * @returns {number} 比较结果
 */
function compareVersions(v1, v2) {
    const parts1 = v1.split('.').map(Number);
    const parts2 = v2.split('.').map(Number);
    
    for (let i = 0; i < Math.max(parts1.length, parts2.length); i++) {
        const p1 = parts1[i] || 0;
        const p2 = parts2[i] || 0;
        if (p1 > p2) return 1;
        if (p1 < p2) return -1;
    }
    return 0;
}

/**
 * 显示版本获取错误
 */
function showVersionError() {
    const versionDisplay = document.getElementById('version-display');
    if (versionDisplay) {
        versionDisplay.textContent = '获取失败';
    }
    
    Object.keys(platformConfig).forEach(platform => {
        const config = platformConfig[platform];
        if (config.versionEl) {
            const versionEl = document.getElementById(config.versionEl);
            if (versionEl) {
                versionEl.textContent = '获取失败';
            }
        }
    });
}

/**
 * 更新导航栏背景色
 */
function updateNavbarBackground() {
    const navbar = document.querySelector('.navbar');
    if (!navbar) return;
    
    const scrollY = window.scrollY;
    const isLightTheme = document.documentElement.getAttribute('data-theme') === 'light';
    
    if (scrollY > 100) {
        navbar.style.background = isLightTheme 
            ? 'rgba(255, 255, 255, 0.95)' 
            : 'rgba(10, 10, 15, 0.95)';
    } else {
        navbar.style.background = isLightTheme 
            ? 'rgba(255, 255, 255, 0.8)' 
            : 'rgba(10, 10, 15, 0.8)';
    }
}

/**
 * 主题切换功能
 */
function initThemeToggle() {
    const themeToggle = document.getElementById('theme-toggle');
    const html = document.documentElement;
    
    // 从 localStorage 获取保存的主题
    const savedTheme = localStorage.getItem('theme');
    
    // 初始化主题
    if (savedTheme) {
        html.setAttribute('data-theme', savedTheme);
    } else {
        // 检查系统偏好
        const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
        if (!prefersDark) {
            html.setAttribute('data-theme', 'light');
        }
    }
    
    // 初始化导航栏背景
    updateNavbarBackground();
    
    // 监听系统主题变化
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
        if (!localStorage.getItem('theme')) {
            if (e.matches) {
                html.removeAttribute('data-theme');
            } else {
                html.setAttribute('data-theme', 'light');
            }
            updateNavbarBackground();
        }
    });
    
    // 点击切换主题
    if (themeToggle) {
        themeToggle.addEventListener('click', () => {
            const currentTheme = html.getAttribute('data-theme');
            
            if (currentTheme === 'light') {
                html.removeAttribute('data-theme');
                localStorage.setItem('theme', 'dark');
            } else {
                html.setAttribute('data-theme', 'light');
                localStorage.setItem('theme', 'light');
            }
            
            // 立即更新导航栏背景
            updateNavbarBackground();
        });
    }
}

/**
 * 初始化截图标签切换
 */
function initScreenshotTabs() {
    const tabs = document.querySelectorAll('.screenshot-tab');
    const panels = document.querySelectorAll('.screenshot-panel');
    
    tabs.forEach(tab => {
        tab.addEventListener('click', () => {
            const targetTab = tab.dataset.tab;
            
            tabs.forEach(t => t.classList.remove('active'));
            panels.forEach(p => p.classList.remove('active'));
            
            tab.classList.add('active');
            const targetPanel = document.getElementById(`${targetTab}-panel`);
            if (targetPanel) {
                targetPanel.classList.add('active');
            }
        });
    });
}

/**
 * 初始化滚动动画
 */
function initScrollAnimations() {
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('animate-in');
                observer.unobserve(entry.target);
            }
        });
    }, observerOptions);
    
    const animateElements = document.querySelectorAll('.feature-card, .download-card, .tech-item, .screenshot-item');
    animateElements.forEach(el => {
        el.style.opacity = '0';
        el.style.transform = 'translateY(20px)';
        el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(el);
    });
}

/**
 * 添加动画入场样式
 */
function addAnimateInStyles() {
    const style = document.createElement('style');
    style.textContent = `
        .animate-in {
            opacity: 1 !important;
            transform: translateY(0) !important;
        }
    `;
    document.head.appendChild(style);
}

/**
 * 初始化导航栏滚动效果
 */
function initNavbarScroll() {
    window.addEventListener('scroll', updateNavbarBackground);
}

/**
 * 初始化平滑滚动
 */
function initSmoothScroll() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            const targetId = this.getAttribute('href');
            // 只处理有效的锚点链接，跳过下载链接
            if (!targetId || targetId.length < 2 || !targetId.startsWith('#')) {
                return;
            }
            
            e.preventDefault();
            const targetElement = document.querySelector(targetId);
            
            if (targetElement) {
                const navHeight = document.querySelector('.navbar').offsetHeight;
                const targetPosition = targetElement.offsetTop - navHeight - 20;
                
                window.scrollTo({
                    top: targetPosition,
                    behavior: 'smooth'
                });
            }
        });
    });
}

/**
 * 初始化鼠标跟随效果
 */
function initMouseFollow() {
    const cards = document.querySelectorAll('.feature-card, .download-card:not(.disabled)');
    
    cards.forEach(card => {
        card.addEventListener('mousemove', (e) => {
            const rect = card.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;
            
            card.style.setProperty('--mouse-x', `${x}px`);
            card.style.setProperty('--mouse-y', `${y}px`);
        });
    });
}

/**
 * 页面加载完成后初始化
 */
document.addEventListener('DOMContentLoaded', () => {
    addAnimateInStyles();
    initThemeToggle();
    fetchLatestVersions();
    initScreenshotTabs();
    initScrollAnimations();
    initNavbarScroll();
    initSmoothScroll();
    initMouseFollow();
});
