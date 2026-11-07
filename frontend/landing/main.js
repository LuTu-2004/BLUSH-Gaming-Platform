(function () {
  'use strict';

  var config = window.BLUSH_CONFIG || {};
  document.documentElement.classList.remove('no-js');

  // ── Google Analytics 4 (chỉ gắn khi đã có Measurement ID) ──────
  function track(event, params) {
    if (typeof window.gtag === 'function') window.gtag('event', event, params || {});
  }
  if (config.gaMeasurementId) {
    var ga = document.createElement('script');
    ga.async = true;
    ga.src = 'https://www.googletagmanager.com/gtag/js?id=' + encodeURIComponent(config.gaMeasurementId);
    document.head.appendChild(ga);
    window.dataLayer = window.dataLayer || [];
    window.gtag = function () { window.dataLayer.push(arguments); };
    window.gtag('js', new Date());
    window.gtag('config', config.gaMeasurementId);
  }

  // Nguồn truy cập: ?utm_source=... trên link, không có thì lấy tên trang dẫn tới (google, facebook...)
  function trafficSource() {
    var utm = new URLSearchParams(location.search).get('utm_source');
    if (utm) return utm;
    try {
      return document.referrer ? new URL(document.referrer).hostname.replace(/^www\./, '') : 'direct';
    } catch (e) {
      return 'direct';
    }
  }

  // ── Nút tải APK ──────────────────────────────────────────────
  var apkButton = document.getElementById('apkButton');
  var heroApkButton = document.getElementById('heroApkButton');
  var navApkButton = document.querySelector('.nav-cta');
  var apkMeta = document.getElementById('apkMeta');
  apkMeta.textContent = ['Phiên bản ' + (config.apkVersion || '1.0.1'), 'Android', config.apkSize].filter(Boolean).join(' · ');

  var filename = (config.apkUrl && config.apkUrl.split('/').pop().split('?')[0]) || 'BLUSH-1.0.1.apk';

  [apkButton, heroApkButton, navApkButton].filter(Boolean).forEach(function (btn) {
    if (config.apkUrl) {
      btn.href = config.apkUrl;
      btn.setAttribute('download', filename);
    }
    btn.addEventListener('click', function (e) {
      track('download_apk', { source: trafficSource(), version: config.apkVersion });
      if (!config.apkUrl) {
        e.preventDefault();
        apkMeta.textContent = 'Bản APK sắp có, bạn quay lại sau ít hôm nhé!';
        apkMeta.classList.add('notice');
      }
    });
  });
  // Các nút "Tải" khác chỉ cuộn xuống mục tải app: ghi lại để biết nút nào được bấm nhiều
  document.querySelectorAll('[data-download]').forEach(function (el) {
    if (el !== apkButton) el.addEventListener('click', function () { track('click_download_cta', { label: el.textContent.trim() }); });
  });

  // ── Thanh trên cùng: nền mờ khi cuộn, menu trên điện thoại ─────
  var nav = document.getElementById('nav');
  var onScroll = function () { nav.classList.toggle('scrolled', window.scrollY > 10); };
  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();

  var toggle = document.getElementById('navToggle');
  var links = document.getElementById('navLinks');
  var setMenu = function (open) {
    links.classList.toggle('open', open);
    toggle.setAttribute('aria-expanded', String(open));
    toggle.setAttribute('aria-label', open ? 'Đóng menu' : 'Mở menu');
  };
  toggle.addEventListener('click', function () { setMenu(!links.classList.contains('open')); });
  links.addEventListener('click', function (e) { if (e.target.tagName === 'A') setMenu(false); });
  document.addEventListener('keydown', function (e) { if (e.key === 'Escape') setMenu(false); });

  // ── Hiện dần khi cuộn tới (các phần tử cùng hàng hiện lệch nhau một chút) ──
  var items = document.querySelectorAll('.reveal');
  if ('IntersectionObserver' in window) {
    var observer = new IntersectionObserver(function (entries) {
      var batch = 0;
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        entry.target.style.transitionDelay = Math.min(batch++ * 80, 320) + 'ms';
        entry.target.classList.add('in');
        observer.unobserve(entry.target);
      });
    }, { threshold: 0.12, rootMargin: '0px 0px -40px 0px' });
    items.forEach(function (el) { observer.observe(el); });
  } else {
    items.forEach(function (el) { el.classList.add('in'); });
  }

  // ── Thẻ tính năng: quầng sáng chạy theo chuột ────────────────
  document.querySelectorAll('.card-feature').forEach(function (card) {
    card.addEventListener('pointermove', function (e) {
      var r = card.getBoundingClientRect();
      card.style.setProperty('--mx', (e.clientX - r.left) + 'px');
      card.style.setProperty('--my', (e.clientY - r.top) + 'px');
    });
  });

  document.getElementById('year').textContent = new Date().getFullYear();
})();
