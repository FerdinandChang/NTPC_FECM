/**
 * 新北市固定溢散源管理平台 (NTPC_FEC)
 * 外勤現場巡查離線與本機草稿守護器 (FEC Offline Sentinel)
 * 
 * 核心功能：
 * 1. 斷網/弱網即時感知與頂部警報列提示
 * 2. 定時 (每15秒) 自動將外勤表單暫存至 localStorage
 * 3. 頁面重啟或意外中斷時，友善提供一鍵恢復上次草稿進度
 * 4. 表單送出成功後自動銷毀本機草稿
 */
(function (window) {
    'use strict';

    window.FecOfflineSentinel = {
        create: function (options) {
            options = options || {};
            var key = options.storageKey || 'FEC_INSPECTION_DRAFT';
            var getData = options.getData;
            var restoreData = options.restoreData;
            var intervalMs = options.intervalMs || 15000;
            var maxAgeHours = options.maxAgeHours || 48;

            var timer = null;
            var bannerEl = null;

            function ensureNetworkBanner() {
                if (document.getElementById('fecNetworkBanner')) return;
                bannerEl = document.createElement('div');
                bannerEl.id = 'fecNetworkBanner';
                bannerEl.style.cssText = 'position:fixed;top:0;left:0;right:0;z-index:99999;background:linear-gradient(135deg,#d97706,#b45309);color:#ffffff;padding:8px 16px;font-size:0.88rem;font-weight:700;display:none;align-items:center;justify-content:center;box-shadow:0 2px 10px rgba(0,0,0,0.25);text-align:center;transition:all 0.3s ease;';
                bannerEl.innerHTML = '<i class="fas fa-wifi-slash mr-2" style="font-size:1.1rem;"></i><span>現場網路已離線！系統已啟動本機離線安全暫存，您的填寫與評分不會遺失，請待復網後再行送出。</span>';
                document.body.appendChild(bannerEl);
            }

            function updateNetworkStatus() {
                ensureNetworkBanner();
                if (bannerEl) {
                    bannerEl.style.display = navigator.onLine ? 'none' : 'flex';
                }
            }

            window.addEventListener('online', updateNetworkStatus);
            window.addEventListener('offline', updateNetworkStatus);

            function saveDraft() {
                if (typeof getData !== 'function') return;
                try {
                    var data = getData();
                    if (!data) return;
                    var payload = {
                        savedAt: new Date().toISOString(),
                        data: data
                    };
                    localStorage.setItem(key, JSON.stringify(payload));
                } catch (e) {
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
                var alertDiv = document.createElement('div');
                alertDiv.id = 'fecDraftRestoreAlert';
                alertDiv.className = 'alert alert-warning shadow-sm border-warning d-flex align-items-center justify-content-between flex-wrap p-2 px-3 mb-3';
                alertDiv.style.cssText = 'border-radius:10px;font-size:0.9rem;';
                alertDiv.innerHTML =
                    '<div class="d-flex align-items-center my-1">' +
                        '<i class="fas fa-history text-warning mr-2" style="font-size:1.25rem;"></i>' +
                        '<div>' +
                            '<strong>發現未送出的現場暫存草稿！</strong>' +
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

            timer = setInterval(saveDraft, intervalMs);
            updateNetworkStatus();

            return {
                saveDraft: saveDraft,
                clearDraft: clearDraft,
                getExistingDraft: getExistingDraft,
                checkAndPromptRestore: checkAndPromptRestore,
                destroy: function () {
                    if (timer) clearInterval(timer);
                    window.removeEventListener('online', updateNetworkStatus);
                    window.removeEventListener('offline', updateNetworkStatus);
                }
            };
        }
    };
})(window);
