/**
 * 新北市固定逸散源管理平台 (NTPC_FEC)
 * 外勤現場巡查離線與本機草稿守護器 (FEC Offline Sentinel)
 * 
 * 核心功能：
 * 1. 斷網/弱網即時感知與頂部動態狀態列提示 (離線警報 + 復網綠色確認)
 * 2. 定時 (每15秒) 自動將外勤表單暫存至 localStorage
 * 3. 頁面重啟或意外中斷時，友善提供一鍵恢復上次草稿進度
 * 4. 表單送出成功後自動銷毀本機草稿
 * 5. 離線防呆：斷網期間自動提示並防止無效發送
 * 6. Session 逾期心跳防護：巡查作業期間主動維持工作階段，閒置達 25 分鐘時彈出警示
 */
(function (window) {
    'use strict';

    function FecOfflineSentinel(options) {
        return FecOfflineSentinel.create(options);
    }

    FecOfflineSentinel.create = function (options) {
        options = options || {};
        var key = options.storageKey || 'FEC_INSPECTION_DRAFT';
        var getData = options.getData || options.onSave;
        var restoreData = options.restoreData || options.onRestore;
        var intervalMs = options.intervalMs || 15000;
        var maxAgeHours = options.maxAgeHours || 48;
        var enableSessionKeeper = options.enableSessionKeeper !== false;

            var timer = null;
            var bannerEl = null;
            var onlineNoticeTimer = null;
            var sessionTimer = null;
            var lastActiveTime = Date.now();
            var lastPingTime = Date.now();

            // 1. 網路狀態橫幅
            function ensureNetworkBanner() {
                if (document.getElementById('fecNetworkBanner')) {
                    bannerEl = document.getElementById('fecNetworkBanner');
                    return;
                }
                bannerEl = document.createElement('div');
                bannerEl.id = 'fecNetworkBanner';
                bannerEl.style.cssText = 'position:fixed;top:0;left:0;right:0;z-index:99999;color:#ffffff;padding:9px 16px;font-size:0.9rem;font-weight:700;display:none;align-items:center;justify-content:center;box-shadow:0 3px 12px rgba(0,0,0,0.25);text-align:center;transition:all 0.3s ease;';
                document.body.appendChild(bannerEl);
            }

            function updateNetworkStatus(evt) {
                ensureNetworkBanner();
                if (!bannerEl) return;

                if (!navigator.onLine) {
                    if (onlineNoticeTimer) clearTimeout(onlineNoticeTimer);
                    bannerEl.style.background = 'linear-gradient(135deg, #d97706, #b45309)';
                    bannerEl.innerHTML = '<i class="fas fa-wifi-slash mr-2" style="font-size:1.15rem;"></i><span>【離線模式】現場網路已中斷！系統已啟動本機離線安全暫存，請待復網後再行送出。</span>';
                    bannerEl.style.display = 'flex';
                } else if (evt && evt.type === 'online') {
                    bannerEl.style.background = 'linear-gradient(135deg, #059669, #047857)';
                    bannerEl.innerHTML = '<i class="fas fa-wifi mr-2" style="font-size:1.15rem;"></i><span>【連線恢復】網路已恢復連線！您可以正常送出查核表單。</span>';
                    bannerEl.style.display = 'flex';
                    if (onlineNoticeTimer) clearTimeout(onlineNoticeTimer);
                    onlineNoticeTimer = setTimeout(function () {
                        if (bannerEl) bannerEl.style.display = 'none';
                    }, 3500);
                } else {
                    bannerEl.style.display = 'none';
                }
            }

            window.addEventListener('online', updateNetworkStatus);
            window.addEventListener('offline', updateNetworkStatus);

            // 2. 避免 LocalStorage Quota 塞爆之大圖剝離
            function stripHeavyData(obj) {
                if (!obj || typeof obj !== 'object') return obj;
                if (Array.isArray(obj)) {
                    return obj.map(function (item) {
                        return stripHeavyData(item);
                    });
                }
                var clean = {};
                for (var prop in obj) {
                    if (Object.prototype.hasOwnProperty.call(obj, prop)) {
                        var val = obj[prop];
                        if (typeof val === 'string' && val.length > 512 && (val.indexOf('data:image') === 0 || prop.toLowerCase().indexOf('base64') >= 0)) {
                            clean[prop] = null;
                        } else if (typeof val === 'object') {
                            clean[prop] = stripHeavyData(val);
                        } else {
                            clean[prop] = val;
                        }
                    }
                }
                return clean;
            }

            // 3. 自動暫存
            function saveDraft() {
                if (typeof getData !== 'function') return;
                try {
                    var data = getData();
                    if (!data) return;
                    var payload = {
                        savedAt: new Date().toISOString(),
                        degraded: false,
                        data: data
                    };
                    localStorage.setItem(key, JSON.stringify(payload));
                } catch (e) {
                    if (e && (e.name === 'QuotaExceededError' || e.code === 22 || e.code === 1014)) {
                        try {
                            var stripped = stripHeavyData(getData());
                            var fallbackPayload = {
                                savedAt: new Date().toISOString(),
                                degraded: true,
                                data: stripped
                            };
                            localStorage.setItem(key, JSON.stringify(fallbackPayload));
                            console.warn('[FEC Sentinel] 本機草稿因圖片體積超出配額已啟用降級保存 (核心表單數值已完整保留)');
                        } catch (err2) {
                        }
                    }
                }
            }

            function getExistingDraft() {
                try {
                    var raw = localStorage.getItem(key);
                    if (!raw) return null;
                    var parsed = JSON.parse(raw);
                    if (!parsed || !parsed.savedAt) return null;
                    var ageHours = (new Date() - new Date(parsed.savedAt)) / (1000 * 60 * 60);
                    if (ageHours > maxAgeHours) {
                        localStorage.removeItem(key);
                        return null;
                    }
                    return parsed;
                } catch (e) {
                    return null;
                }
            }

            function clearDraft() {
                try {
                    localStorage.removeItem(key);
                } catch (e) { }
            }

            function checkAndPromptRestore(containerEl) {
                var draft = getExistingDraft();
                if (!draft) return;

                var timeStr = new Date(draft.savedAt).toLocaleString();
                var degradedTip = draft.degraded ? ' <span class="badge badge-secondary ml-1" style="font-size:0.75rem;">僅核心表單 (照片容量超出已略過)</span>' : '';
                var alertDiv = document.createElement('div');
                alertDiv.id = 'fecDraftRestoreAlert';
                alertDiv.className = 'alert alert-warning shadow-sm border-warning d-flex align-items-center justify-content-between flex-wrap p-2 px-3 mb-3';
                alertDiv.style.cssText = 'border-radius:10px;font-size:0.9rem;';
                alertDiv.innerHTML =
                    '<div class="d-flex align-items-center my-1">' +
                        '<i class="fas fa-history text-warning mr-2" style="font-size:1.25rem;"></i>' +
                        '<div>' +
                            '<strong>發現未送出的現場暫存草稿！</strong>' + degradedTip +
                            '<div class="small text-muted">暫存時間：' + timeStr + '</div>' +
                        '</div>' +
                    '</div>' +
                    '<div class="d-flex align-items-center my-1" style="gap:8px;">' +
                        '<button type="button" class="btn btn-sm btn-warning font-weight-bold" id="btnFecRestoreDraft">' +
                            '<i class="fas fa-magic mr-1"></i>一鍵恢復進度' +
                        '</button>' +
                        '<button type="button" class="btn btn-sm btn-outline-secondary" id="btnFecDiscardDraft">' +
                            '<i class="fas fa-trash-alt mr-1"></i>捨棄草稿' +
                        '</button>' +
                    '</div>';

                var target = containerEl || document.querySelector('.container-fluid') || document.body.firstChild;
                if (target) {
                    if (target.parentNode && target !== document.body) {
                        target.parentNode.insertBefore(alertDiv, target);
                    } else {
                        document.body.insertBefore(alertDiv, document.body.firstChild);
                    }
                }

                var btnRestore = document.getElementById('btnFecRestoreDraft');
                if (btnRestore) {
                    btnRestore.onclick = function () {
                        if (typeof restoreData === 'function') {
                            restoreData(draft.data);
                        }
                        if (alertDiv && alertDiv.parentNode) {
                            alertDiv.parentNode.removeChild(alertDiv);
                        }
                    };
                }

                var btnDiscard = document.getElementById('btnFecDiscardDraft');
                if (btnDiscard) {
                    btnDiscard.onclick = function () {
                        clearDraft();
                        if (alertDiv && alertDiv.parentNode) {
                            alertDiv.parentNode.removeChild(alertDiv);
                        }
                    };
                }
            }

            function isOnline() {
                return navigator.onLine;
            }

            // 4. Session 活躍監聽與自動心跳維持
            function onUserActivity() {
                lastActiveTime = Date.now();
                hideSessionWarning();
            }

            ['click', 'keydown', 'touchstart', 'scroll'].forEach(function (evtName) {
                window.addEventListener(evtName, onUserActivity, { passive: true });
            });

            function pingServer() {
                if (!navigator.onLine) return;
                lastPingTime = Date.now();
                lastActiveTime = Date.now();
                hideSessionWarning();

                try {
                    var xhr = new XMLHttpRequest();
                    xhr.open('HEAD', window.location.href.split('?')[0] + '?_keepalive=' + Date.now(), true);
                    xhr.send();
                } catch (e) {
                }
            }

            function showSessionWarning() {
                if (document.getElementById('fecSessionWarnModal')) return;
                var modal = document.createElement('div');
                modal.id = 'fecSessionWarnModal';
                modal.style.cssText = 'position:fixed;bottom:24px;right:24px;z-index:99998;max-width:380px;background:#ffffff;border:2px solid #f59e0b;border-radius:12px;box-shadow:0 10px 25px rgba(0,0,0,0.2);padding:16px;font-family:sans-serif;';
                modal.innerHTML =
                    '<div style="display:flex;align-items:flex-start;gap:12px;">' +
                        '<div style="color:#d97706;font-size:1.5rem;line-height:1;"><i class="fas fa-hourglass-half"></i></div>' +
                        '<div style="flex:1;">' +
                            '<h6 style="margin:0 0 6px 0;font-size:0.95rem;font-weight:700;color:#1e293b;">登入作業階段即將逾期</h6>' +
                            '<p style="margin:0 0 12px 0;font-size:0.83rem;color:#64748b;line-height:1.4;">您已閒置近 25 分鐘。為維護資料安全，系統即將於 5 分鐘後自動登出。若需繼續填寫請點擊下方按鈕維持連線。</p>' +
                            '<div style="display:flex;gap:8px;">' +
                                '<button type="button" id="btnKeepSessionAlive" style="background:#059669;color:#ffffff;border:none;border-radius:6px;padding:6px 14px;font-size:0.85rem;font-weight:700;cursor:pointer;">保持登入狀態</button>' +
                            '</div>' +
                        '</div>' +
                    '</div>';
                document.body.appendChild(modal);

                var btn = document.getElementById('btnKeepSessionAlive');
                if (btn) {
                    btn.onclick = function () {
                        pingServer();
                    };
                }
            }

            function hideSessionWarning() {
                var modal = document.getElementById('fecSessionWarnModal');
                if (modal && modal.parentNode) {
                    modal.parentNode.removeChild(modal);
                }
            }

            function checkSessionHeartbeat() {
                if (!enableSessionKeeper) return;
                var now = Date.now();
                var idleMs = now - lastActiveTime;
                var sinceLastPingMs = now - lastPingTime;

                // 若使用者持續有操作，且距離上次心跳超過 12 分鐘，主動安靜 Ping 伺服器延長 Session
                if (idleMs < 10 * 60 * 1000 && sinceLastPingMs > 12 * 60 * 1000) {
                    pingServer();
                }
                // 若閒置達到 25 分鐘，跳出提醒視窗
                else if (idleMs >= 25 * 60 * 1000 && idleMs < 30 * 60 * 1000) {
                    showSessionWarning();
                }
            }

            timer = setInterval(saveDraft, intervalMs);
            sessionTimer = setInterval(checkSessionHeartbeat, 30000); // 每 30 秒檢視一次
            updateNetworkStatus();

            return {
                saveDraft: saveDraft,
                clearDraft: clearDraft,
                getExistingDraft: getExistingDraft,
                checkAndPromptRestore: checkAndPromptRestore,
                isOnline: isOnline,
                pingServer: pingServer,
                destroy: function () {
                    if (timer) clearInterval(timer);
                    if (sessionTimer) clearInterval(sessionTimer);
                    if (onlineNoticeTimer) clearTimeout(onlineNoticeTimer);
                    window.removeEventListener('online', updateNetworkStatus);
                    window.removeEventListener('offline', updateNetworkStatus);
                    ['click', 'keydown', 'touchstart', 'scroll'].forEach(function (evtName) {
                        window.removeEventListener(evtName, onUserActivity);
                    });
                }
            };
        };

        window.FecOfflineSentinel = FecOfflineSentinel;
})(window);
