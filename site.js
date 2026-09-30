
    (() => {
      const video = document.getElementById('yt-card');
      const sidebar = document.querySelector('.sidebar');
      const main = document.querySelector('main');
      const footer = document.querySelector('.footer');
      if (!video || !sidebar || !main || !footer) return;
      const mobile = matchMedia('(max-width: 900px)');
      const placeVideo = () => {
        if (mobile.matches) main.insertBefore(video, footer);
        else sidebar.appendChild(video);
      };
      mobile.addEventListener('change', placeVideo);
      placeVideo();
    })();

    (() => {
      const products = {
        cicho: {
          title: 'Cicho',
          tagline: 'Find places to work nearby',
          icon: 'cicho.png',
          desc: 'For remote workers and digital nomads. Discover spots with reliable wifi, power outlets, and the right noise level within 5km of where you are.',
          meta: ['iOS', 'Live', 'App Store'],
          action: 'View on App Store →',
          href: 'https://apps.apple.com/pl/app/cicho/id6765781671'
        },
        ozaio: {
          title: 'Ozaio',
          tagline: 'A tiny zen space',
          icon: 'ozaio.png',
          desc: 'Short pauses, a quiet inner garden, and a few daily things to track. Made for moments when you need a soft reset during the day.',
          meta: ['iOS', 'Live', 'App Store'],
          action: 'View on App Store →',
          href: 'https://apps.apple.com/pl/app/ozaio/id6757318842'
        },
        neural: {
          title: 'Neural Blitz',
          tagline: 'Fast daily brain challenges',
          icon: 'neural-blitz.png',
          desc: 'Quick logic, focus, math, word, grammar, recall, and decision games. Build your Neural Score, keep your streak alive, and climb the leaderboard.',
          meta: ['iOS', 'Live', 'Game'],
          action: 'View on App Store →',
          href: 'https://apps.apple.com/pl/app/neural-blitz/id6772118304'
        },
        simitci: {
          title: 'Simitçi Simülasyonu',
          tagline: 'Istanbul street shop simulator',
          icon: 'simitci-rush-small.png',
          desc: 'A mobile Istanbul shop simulator about serving customers, managing stock, setting prices, upgrading your stand, and surviving the daily rush.',
          meta: ['iOS', 'Live', 'Game'],
          action: 'Open on App Store →',
          href: 'https://apps.apple.com/pl/app/simit%C3%A7i-sim%C3%BClasyonu/id6777099985'
        },
        finance: {
          title: 'Tota Finance',
          tagline: 'Personal tracking dashboard',
          icon: 'tota-finance.png',
          desc: 'A clean web dashboard for tracking personal spending, savings goals, and net worth over time. Built for makers who want clarity without spreadsheets.',
          meta: ['Web', 'Live', 'Dashboard'],
          action: 'Open Dashboard →',
          href: 'https://tota-finance.com'
        },
        flo: {
          title: 'Flo',
          tagline: 'Finance companion tool',
          icon: 'tota-finance.png',
          desc: 'A companion tool to Tota Finance. Currently in development and not publicly accessible yet.',
          meta: ['Web', 'In development', 'Private'],
          action: 'In development',
          href: ''
        },
        fornow: {
          title: 'ForNow',
          tagline: 'A digital pocket for your Mac',
          icon: 'fornow-small.png',
          desc: 'A lightweight place to keep files, links, notes, and anything else you only need for now. Close at hand when you need it, out of the way when you do not.',
          meta: ['macOS', 'Live', 'Mac App Store'],
          action: 'Open on Mac App Store →',
          href: 'https://apps.apple.com/pl/app/fornow/id6784813371?mt=12'
        },
        perihelix: {
          title: 'Perihelix',
          tagline: 'One-finger orbital arcade',
          icon: 'perihelix.svg',
          desc: 'A minimalist arcade game. Hold to pull inward, release to drift outward, dodge orbital hazards, and chase cleaner runs.',
          meta: ['iOS', 'Live', 'Game'],
          action: 'Open on App Store →',
          href: 'https://apps.apple.com/pl/app/perihelix/id6786785305'
        }
      };

      const studio = document.getElementById('product-studio');
      const productCanvas = studio?.querySelector('.product-canvas');
      const tabs = [...document.querySelectorAll('.product-tab')];
      const floatingApps = [...document.querySelectorAll('.floating-app')];
      const detailIcon = document.getElementById('detail-icon');
      const detailTitle = document.getElementById('detail-title');
      const detailTagline = document.getElementById('detail-tagline');
      const detailDesc = document.getElementById('detail-desc');
      const detailMeta = document.getElementById('detail-meta');
      const detailAction = document.getElementById('detail-action');
      const viewButtons = [...document.querySelectorAll('[data-view]')];
      const appStoreBadgeMarkup = (storeName = 'App Store') => `
        <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M17.04 12.44c-.02-2.2 1.8-3.25 1.88-3.3-1.03-1.5-2.62-1.71-3.18-1.73-1.35-.14-2.64.8-3.33.8-.69 0-1.75-.78-2.88-.76-1.48.02-2.85.86-3.61 2.19-1.54 2.67-.39 6.63 1.11 8.8.73 1.06 1.61 2.25 2.76 2.21 1.1-.04 1.52-.72 2.86-.72 1.33 0 1.72.72 2.89.7 1.19-.02 1.95-1.08 2.68-2.14.84-1.23 1.19-2.42 1.21-2.48-.03-.01-2.36-.91-2.39-3.57zM14.85 5.98c.61-.74 1.02-1.77.91-2.8-.88.04-1.95.59-2.58 1.32-.57.66-1.06 1.71-.93 2.72.98.08 1.98-.5 2.6-1.24z"/></svg>
        <span class="app-store-copy"><small>Download on the</small><strong>${storeName}</strong></span>
      `;

      const setView = (view) => {
        viewButtons.forEach((button) => {
          const selected = button.dataset.view === view;
          button.classList.toggle('active', selected);
          button.setAttribute('aria-pressed', String(selected));
        });
        studio?.classList.toggle('wall', view === 'wall');
      };

      const selectProduct = (id) => {
        const product = products[id];
        if (!product || !detailIcon || !detailTitle || !detailTagline || !detailDesc || !detailMeta || !detailAction) return;

        tabs.forEach((tab) => {
          const selected = tab.dataset.product === id;
          tab.classList.toggle('active', selected);
          tab.setAttribute('aria-pressed', String(selected));
        });
        floatingApps.forEach((app) => app.classList.toggle('active', app.dataset.product === id));

        detailIcon.src = product.icon;
        detailIcon.alt = '';
        detailTitle.textContent = product.title;
        detailTagline.textContent = product.tagline;
        detailDesc.textContent = product.desc;

        detailMeta.textContent = '';
        product.meta.forEach((item) => {
          const pill = document.createElement('span');
          pill.className = 'meta-pill';
          pill.textContent = item;
          detailMeta.appendChild(pill);
        });

        const isAppStore = product.href.includes('apps.apple.com');
        detailAction.classList.toggle('app-store-badge', isAppStore);
        if (isAppStore) {
          const storeName = product.meta.includes('Mac App Store') ? 'Mac App Store' : 'App Store';
          detailAction.innerHTML = appStoreBadgeMarkup(storeName);
          detailAction.setAttribute('aria-label', `Download ${product.title} on the ${storeName}`);
        } else {
          detailAction.textContent = product.action;
          detailAction.removeAttribute('aria-label');
        }
        detailAction.classList.toggle('disabled', !product.href);
        if (product.href) {
          detailAction.href = product.href;
          detailAction.setAttribute('target', '_blank');
          detailAction.setAttribute('rel', 'noopener');
        } else {
          detailAction.removeAttribute('href');
          detailAction.removeAttribute('target');
          detailAction.removeAttribute('rel');
        }
      };

      tabs.forEach((tab) => {
        tab.addEventListener('click', () => {
          selectProduct(tab.dataset.product);
          setView('focus');
        });
      });

      floatingApps.forEach((app) => {
        const openProduct = () => {
          selectProduct(app.dataset.product);
          setView('focus');
        };
        app.addEventListener('click', openProduct);
        app.addEventListener('keydown', (event) => {
          if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            openProduct();
          }
        });
      });

      viewButtons.forEach((button) => {
        button.addEventListener('click', () => {
          setView(button.dataset.view);
        });
      });

      setView('focus');
      selectProduct('cicho');
      if (studio && productCanvas && matchMedia('(hover: hover) and (pointer: fine) and (prefers-reduced-motion: no-preference)').matches) {
        studio.addEventListener('pointermove', (event) => {
          const bounds = studio.getBoundingClientRect();
          const x = ((event.clientX - bounds.left) / bounds.width - 0.5) * 8;
          const y = ((event.clientY - bounds.top) / bounds.height - 0.5) * 6;
          productCanvas.style.transform = `translate3d(${x}px, ${y}px, 0)`;
        });
        studio.addEventListener('pointerleave', () => {
          productCanvas.style.transform = '';
        });
      }
    })();

    (async () => {
      try {
        const res = await fetch('/latest-update.json', { cache: 'no-cache' });
        if (!res.ok) return;
        const update = await res.json();

        const card = document.getElementById('latest-x-card');
        const label = document.getElementById('latest-x-label');
        const title = document.getElementById('latest-x-title');
        const copy = document.getElementById('latest-x-copy');
        const cta = document.getElementById('latest-x-cta');
        if (!card || !label || !title || !copy || !cta) return;

        const safeUrl = typeof update.url === 'string' &&
          /^https:\/\/(x|twitter)\.com\/[A-Za-z0-9_]+(\/status\/[0-9]+)?\/?([?#][^\s<>"']*)?$/.test(update.url)
            ? update.url
            : null;
        if (!safeUrl) return;

        card.href = safeUrl;
        if (typeof update.label === 'string' && update.label.trim()) label.textContent = update.label.trim();
        if (typeof update.title === 'string' && update.title.trim()) title.textContent = update.title.trim();
        if (typeof update.text === 'string' && update.text.trim()) copy.textContent = update.text.trim();
        if (typeof update.cta === 'string' && update.cta.trim()) cta.textContent = update.cta.trim();
      } catch (e) { /* keep static latest update fallback */ }
    })();

    // Fetch the latest YouTube video through the same-origin Vercel rewrite.
    // Falls back to the latest known published video if the feed is unavailable.
    (async () => {
      const feed = '/youtube-feed.xml';

      const fallbackVideo = {
        videoId: '6xuXSsEMf4g',
        title: 'Money Reveals What You Obey | Future Lesson #003',
        link: 'https://www.youtube.com/watch?v=6xuXSsEMf4g',
        status: 'Featured video'
      };

      const renderVideo = ({ videoId, title, link, status }) => {
        const card    = document.getElementById('yt-card');
        const thumb   = document.getElementById('yt-thumb');
        const statusEl = document.getElementById('yt-status');
        const titleEl = document.getElementById('yt-title');
        if (!card || !thumb || !statusEl || !titleEl) return;

        thumb.textContent = '';
        const img = document.createElement('img');
        img.src = `https://i.ytimg.com/vi/${videoId}/hqdefault.jpg`;
        img.alt = title;
        img.loading = 'lazy';

        const playWrap = document.createElement('div');
        playWrap.className = 'yt-play';
        playWrap.style.position = 'absolute';
        const playIcon = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
        playIcon.setAttribute('width', '18');
        playIcon.setAttribute('height', '18');
        playIcon.setAttribute('viewBox', '0 0 24 24');
        playIcon.setAttribute('fill', '#fff');
        const playPath = document.createElementNS('http://www.w3.org/2000/svg', 'path');
        playPath.setAttribute('d', 'M8 5v14l11-7z');
        playIcon.appendChild(playPath);
        playWrap.appendChild(playIcon);

        thumb.appendChild(img);
        thumb.appendChild(playWrap);

        card.href = link;
        statusEl.textContent = status;
        titleEl.textContent = title;
      };

      renderVideo(fallbackVideo);

      try {
        const res = await fetch(feed, { cache: 'no-cache' });
        if (!res.ok) return;
        const xml = await res.text();
        const doc = new DOMParser().parseFromString(xml, 'text/xml');
        if (doc.querySelector('parsererror')) return;

        for (const entry of doc.querySelectorAll('entry')) {

        // YouTube RSS uses <yt:videoId> (namespaced). The <id> tag
        // contains "yt:video:VIDEO_ID" — we extract from there to avoid
        // namespace parsing pitfalls.
        const rawId = entry.querySelector('id')?.textContent || '';
        const videoIdMatch = rawId.match(/yt:video:([A-Za-z0-9_-]{11})/);
        const videoId = videoIdMatch ? videoIdMatch[1] : null;

        const title = entry.querySelector('title')?.textContent || '';
        const link = entry.querySelector('link')?.getAttribute('href') || '';
        const publishedAt = new Date(entry.querySelector('published')?.textContent || 0);

        // Whitelist video ID (must be exactly 11 chars, alphanum + - + _)
        if (!videoId || !/^[A-Za-z0-9_-]{11}$/.test(videoId)) continue;
        if (!title) continue;

        // Skip YouTube's auto-titled empty live streams ("X Canlı Yayını", "X Live Stream")
        // and anything published before this channel's real-content era.
        const MIN_DATE = new Date('2026-05-01');
        const isAutoLiveTitle = /(canlı\s*yayın[ıi]?|live\s*stream)$/i.test(title.trim());
        if (isAutoLiveTitle) continue;
        if (!Number.isFinite(publishedAt.getTime()) || publishedAt < MIN_DATE) continue;

        // Only accept https YouTube links
        const safeLink = /^https:\/\/(www\.)?youtube\.com\//.test(link)
          ? link
          : `https://www.youtube.com/watch?v=${videoId}`;

        renderVideo({ videoId, title, link: safeLink, status: 'Latest video' });
        break;
        }
      } catch (e) { /* silent fail — keep fallback video */ }
    })();
