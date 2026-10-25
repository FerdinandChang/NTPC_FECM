/**
 * 新北市固定溢散源管理平台 (NTPC_FEC)
 * 外勤現場照片前端自動等比縮圖與壓縮工具 (FEC Image Compressor)
 * 
 * 核心功能：
 * 1. 外勤高畫質手機照片 (12MP~50MP，單張 8MB~15MB) 自動等比縮圖至適當解析度 (最長邊 1600px)
 * 2. 高品質 JPEG 壓縮 (預設 0.82)，體積降至 200KB~400KB (壓縮率 95%+)
 * 3. 避免外勤行動網路卡頓與 IIS Request Limits 擋請求
 * 4. 支援 Promise 與 Callback 雙模式調用
 */
(function (window) {
    'use strict';

    var FecImageCompressor = {
        /**
         * 壓縮圖片檔案
         * @param {File} file 原始上傳圖片物件
         * @param {Object} options 設定選項 { maxDimension: 1600, quality: 0.82 }
         * @param {Function} [callback] 完成回呼 function(err, result)
         * @returns {Promise} 若支援 Promise 則返回
         */
        compress: function (file, options, callback) {
            options = options || {};
            var maxDim = options.maxDimension || 1600;
            var quality = typeof options.quality === 'number' ? options.quality : 0.82;

            if (typeof options === 'function') {
                callback = options;
                maxDim = 1600;
                quality = 0.82;
            }

            var doCompress = function (resolve, reject) {
                if (!file) {
                    var errNull = new Error('未提供欲壓縮的檔案物件');
                    if (callback) callback(errNull, null);
                    if (reject) reject(errNull);
                    return;
                }

                if (!file.type || file.type.indexOf('image/') !== 0) {
                    // 非圖片格式，直接以 FileReader 讀取為 DataURL
                    var r = new FileReader();
                    r.onload = function (e) {
                        var res = {
                            base64: e.target.result,
                            dataUrl: e.target.result,
                            originalSize: file.size,
                            compressedSize: file.size,
                            isCompressed: false
                        };
                        if (callback) callback(null, res);
                        if (resolve) resolve(res);
                    };
                    r.onerror = function (e) {
                        if (callback) callback(e, null);
                        if (reject) reject(e);
                    };
                    r.readAsDataURL(file);
                    return;
                }

                var reader = new FileReader();
                reader.onload = function (e) {
                    var img = new Image();
                    img.onload = function () {
                        try {
                            var w = img.width;
                            var h = img.height;

                            if (w > maxDim || h > maxDim) {
                                if (w > h) {
                                    h = Math.round((h * maxDim) / w);
                                    w = maxDim;
                                } else {
                                    w = Math.round((w * maxDim) / h);
                                    h = maxDim;
                                }
                            }

                            var canvas = document.createElement('canvas');
                            canvas.width = w;
                            canvas.height = h;

                            var ctx = canvas.getContext('2d');
                            ctx.drawImage(img, 0, 0, w, h);

                            var compressedBase64 = canvas.toDataURL('image/jpeg', quality);
                            var head = 'data:image/jpeg;base64,';
                            var rawLength = compressedBase64.length - head.length;
                            var approxBytes = Math.round((rawLength * 3) / 4);

                            var result = {
                                base64: compressedBase64,
                                dataUrl: compressedBase64,
                                width: w,
                                height: h,
                                originalSize: file.size,
                                compressedSize: approxBytes,
                                isCompressed: true
                            };

                            // 清理釋放記憶體
                            canvas.width = 0;
                            canvas.height = 0;
                            img = null;

                            if (callback) callback(null, result);
                            if (resolve) resolve(result);
                        } catch (err) {
                            if (callback) callback(err, null);
                            if (reject) reject(err);
                        }
                    };
                    img.onerror = function (err) {
                        if (callback) callback(err, null);
                        if (reject) reject(err);
                    };
                    img.src = e.target.result;
                };
                reader.onerror = function (err) {
                    if (callback) callback(err, null);
                    if (reject) reject(err);
                };
                reader.readAsDataURL(file);
            };

            if (typeof Promise !== 'undefined') {
                return new Promise(doCompress);
            } else {
                doCompress();
            }
        }
    };

    window.FecImageCompressor = FecImageCompressor;
})(window);
