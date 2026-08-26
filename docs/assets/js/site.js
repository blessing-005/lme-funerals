(() => {
  const menu = document.querySelector('.menu-toggle');
  const nav = document.querySelector('#site-nav');
  if (menu && nav) menu.addEventListener('click', () => { const open = nav.classList.toggle('open'); menu.setAttribute('aria-expanded', String(open)); });
  document.querySelectorAll('#site-nav a').forEach(a => a.addEventListener('click', () => { nav?.classList.remove('open'); menu?.setAttribute('aria-expanded','false'); }));
  const dialog = document.querySelector('.lightbox');
  const items = [...document.querySelectorAll('[data-lightbox]')]; let current = 0; let touchX = 0;
  const show = n => { if (!dialog || !items.length) return; current=(n+items.length)%items.length; const img=dialog.querySelector('img'); img.src=items[current].dataset.full; img.alt=items[current].querySelector('img')?.alt||'Portfolio image'; };
  items.forEach((item,i)=>item.addEventListener('click',()=>{show(i);dialog.showModal();}));
  dialog?.querySelector('.lightbox-close')?.addEventListener('click',()=>dialog.close());
  dialog?.querySelector('.lightbox-prev')?.addEventListener('click',()=>show(current-1));
  dialog?.querySelector('.lightbox-next')?.addEventListener('click',()=>show(current+1));
  dialog?.addEventListener('click',e=>{if(e.target===dialog)dialog.close();});
  dialog?.addEventListener('keydown',e=>{if(e.key==='ArrowLeft')show(current-1);if(e.key==='ArrowRight')show(current+1);});
  dialog?.addEventListener('touchstart',e=>touchX=e.changedTouches[0].clientX,{passive:true});
  dialog?.addEventListener('touchend',e=>{const d=e.changedTouches[0].clientX-touchX;if(Math.abs(d)>50)show(current+(d<0?1:-1));},{passive:true});
  const compose = form => { const data=new FormData(form); return [...data.entries()].filter(([,v])=>String(v).trim()).map(([k,v])=>`${k.replaceAll('_',' ')}: ${v}`).join('\n'); };
  document.querySelectorAll('[data-contact-form]').forEach(form => {
    form.addEventListener('submit',e=>{e.preventDefault();const text=compose(form);window.open(`https://wa.me/${form.dataset.phone}?text=${encodeURIComponent(text)}`,'_blank','noopener');form.querySelector('.form-status').textContent='WhatsApp opened with your enquiry. Send it there to reach the team.';});
    form.querySelector('[data-email-submit]')?.addEventListener('click',()=>{if(!form.reportValidity())return;window.location.href=`mailto:${form.dataset.email}?subject=${encodeURIComponent(form.dataset.subject)}&body=${encodeURIComponent(compose(form))}`;});
  });
})();