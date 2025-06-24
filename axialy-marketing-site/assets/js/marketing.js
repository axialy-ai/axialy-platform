// assets/js/marketing.js – minimal helper
document.addEventListener('click', (ev) => {
  const link = ev.target.closest('a[href^="#"]');
  if (!link) return;
  ev.preventDefault();
  const target = document.querySelector(link.getAttribute('href'));
  target?.scrollIntoView({ behavior: 'smooth', block: 'start' });
});
