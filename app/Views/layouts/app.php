<?php
use App\Core\{Auth,Session,Csrf};
$user=Auth::user();
$isLogin = str_contains($viewFile ?? '', '/auth/');
$path=parse_url($_SERVER['REQUEST_URI']??'/',PHP_URL_PATH) ?: '/';
$isActive=static function(string $href) use($path): string {
    if($href==='/dashboard'||$href==='/platform') return $path===$href?'active':'';
    return str_starts_with($path,$href)?'active':'';
};
$can=static fn(string ...$permissions): bool => Auth::isPlatformAdmin() || (bool)array_filter($permissions,fn($p)=>Auth::can($p));
?>
<!doctype html>
<html lang="id" data-bs-theme="light">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <meta name="color-scheme" content="light dark">
  <title><?= e($title ?? config('name')) ?> · <?= e(config('name')) ?></title>
  <link rel="preconnect" href="https://cdn.jsdelivr.net">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css" rel="stylesheet">
  <link href="https://cdn.datatables.net/2.1.8/css/dataTables.bootstrap5.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/fullcalendar@6.1.15/index.global.min.css" rel="stylesheet">
  <script>try{const saved=localStorage.getItem('servicepro-theme');const accountTheme=<?= json_encode($user['theme']??'system') ?>;const t=saved||accountTheme||'system';document.documentElement.setAttribute('data-bs-theme',t==='system'?(matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light'):t)}catch(e){}</script>
  <link rel="stylesheet" href="<?= url('/assets/css/app.css') ?>">
</head>
<body style="--sp-primary:<?= e($user['tenant_color']??'#335CFF') ?>">
<?php if($isLogin): ?>
<?= $content ?>
<?php else: ?>
<div class="app-shell">
<aside class="sidebar" id="sidebar">
  <div class="brand"><div class="brand-mark">SP</div><div class="brand-copy"><strong>ServicePro</strong><small><?= e($user['tenant_name'] ?? 'Platform') ?></small></div><button class="sidebar-close btn d-lg-none" id="sidebarClose" type="button"><i class="bi bi-x-lg"></i></button></div>
  <nav class="nav flex-column mt-4 sidebar-nav">
    <?php if(Auth::isPlatformAdmin()): ?>
      <a class="nav-link <?= $isActive('/platform') ?>" href="<?= url('/platform') ?>"><i class="bi bi-command"></i><span>Platform Dashboard</span></a>
    <?php else: ?>
      <a class="nav-link <?= $isActive('/dashboard') ?>" href="<?= url('/dashboard') ?>"><i class="bi bi-grid-1x2"></i><span>Dashboard</span></a>

      <?php if($can('lead.view','customer.view','asset.view')): ?><div class="nav-section">CRM</div><?php endif; ?>
      <?php if(Auth::can('lead.view')): ?><a class="nav-link <?= $isActive('/leads') ?>" href="<?= url('/leads') ?>"><i class="bi bi-funnel"></i><span>Leads</span></a><?php endif; ?>
      <?php if(Auth::can('customer.view')): ?><a class="nav-link <?= $isActive('/customers') ?>" href="<?= url('/customers') ?>"><i class="bi bi-people"></i><span>Customers</span></a><?php endif; ?>
      <?php if(Auth::can('customer.view')): ?><a class="nav-link <?= $isActive('/manage/customer-sites') ?>" href="<?= url('/manage/customer-sites') ?>"><i class="bi bi-geo-alt"></i><span>Customer Sites</span></a><?php endif; ?>
      <?php if(Auth::can('asset.view')): ?><a class="nav-link <?= $isActive('/manage/customer-assets') ?>" href="<?= url('/manage/customer-assets') ?>"><i class="bi bi-cpu"></i><span>Customer Assets</span></a><?php endif; ?>

      <?php if($can('request.view','survey.view','quotation.view','job.view','contract.view')): ?><div class="nav-section">Service</div><?php endif; ?>
      <?php if(Auth::can('request.view')): ?><a class="nav-link <?= $isActive('/service-requests') ?>" href="<?= url('/service-requests') ?>"><i class="bi bi-inbox"></i><span>Service Requests</span></a><?php endif; ?>
      <?php if(Auth::can('survey.view')): ?><a class="nav-link <?= $isActive('/surveys') ?>" href="<?= url('/surveys') ?>"><i class="bi bi-clipboard2-pulse"></i><span>Site Surveys</span></a><?php endif; ?>
      <?php if(Auth::can('quotation.view')): ?><a class="nav-link <?= $isActive('/quotations') ?>" href="<?= url('/quotations') ?>"><i class="bi bi-file-earmark-text"></i><span>Quotations</span></a><?php endif; ?>
      <?php if(Auth::can('job.view')): ?><a class="nav-link <?= $isActive('/jobs') ?>" href="<?= url('/jobs') ?>"><i class="bi bi-tools"></i><span>Job Orders</span></a><?php endif; ?>
      <?php if(Auth::can('catalog.view')): ?><a class="nav-link <?= $isActive('/manage/service-catalog') ?>" href="<?= url('/manage/service-catalog') ?>"><i class="bi bi-journal-bookmark"></i><span>Service Catalog</span></a><?php endif; ?>
      <?php if(Auth::can('catalog.view')): ?><a class="nav-link <?= $isActive('/manage/service-categories') ?>" href="<?= url('/manage/service-categories') ?>"><i class="bi bi-tags"></i><span>Service Categories</span></a><?php endif; ?>
      <?php if(Auth::can('contract.view')): ?><a class="nav-link <?= $isActive('/manage/contracts') ?>" href="<?= url('/manage/contracts') ?>"><i class="bi bi-file-earmark-check"></i><span>Contracts</span></a><?php endif; ?>
      <?php if(Auth::can('contract.view')): ?><a class="nav-link <?= $isActive('/manage/maintenance') ?>" href="<?= url('/manage/maintenance') ?>"><i class="bi bi-calendar2-check"></i><span>Preventive Maintenance</span></a><?php endif; ?>
      <?php if(Auth::can('contract.view')): ?><a class="nav-link <?= $isActive('/manage/recurring-jobs') ?>" href="<?= url('/manage/recurring-jobs') ?>"><i class="bi bi-arrow-repeat"></i><span>Recurring Jobs</span></a><?php endif; ?>
      <?php if(Auth::can('warranty.view')): ?><a class="nav-link <?= $isActive('/manage/warranties') ?>" href="<?= url('/manage/warranties') ?>"><i class="bi bi-shield-check"></i><span>Warranties</span></a><?php endif; ?>
      <?php if(Auth::can('sla.view')): ?><a class="nav-link <?= $isActive('/manage/sla') ?>" href="<?= url('/manage/sla') ?>"><i class="bi bi-stopwatch"></i><span>SLA Policies</span></a><?php endif; ?>

      <?php if($can('technician.view','dispatch.view','job.view')): ?><div class="nav-section">Field Team</div><?php endif; ?>
      <?php if(Auth::can('technician.view')): ?><a class="nav-link <?= $isActive('/manage/technicians') ?>" href="<?= url('/manage/technicians') ?>"><i class="bi bi-person-gear"></i><span>Technicians</span></a><?php endif; ?>
      <?php if(Auth::can('technician.view')): ?><a class="nav-link <?= $isActive('/manage/skills') ?>" href="<?= url('/manage/skills') ?>"><i class="bi bi-patch-check"></i><span>Skills</span></a><?php endif; ?>
      <?php if(Auth::can('dispatch.view')): ?><a class="nav-link <?= $isActive('/dispatch') ?>" href="<?= url('/dispatch') ?>"><i class="bi bi-calendar3"></i><span>Dispatch & Calendar</span></a><?php endif; ?>

      <?php if($can('inventory.view','purchase.view')): ?><div class="nav-section">Inventory & Purchasing</div><?php endif; ?>
      <?php if(Auth::can('inventory.view')): ?><a class="nav-link <?= $isActive('/inventory') ?>" href="<?= url('/inventory') ?>"><i class="bi bi-box-seam"></i><span>Inventory</span></a><?php endif; ?>
      <?php if(Auth::can('inventory.view')): ?><a class="nav-link <?= $isActive('/manage/warehouses') ?>" href="<?= url('/manage/warehouses') ?>"><i class="bi bi-buildings"></i><span>Warehouses</span></a><?php endif; ?>
      <?php if(Auth::can('purchase.view')): ?><a class="nav-link <?= $isActive('/purchasing') ?>" href="<?= url('/purchasing') ?>"><i class="bi bi-cart3"></i><span>Purchasing</span></a><?php endif; ?>
      <?php if(Auth::can('purchase.view')): ?><a class="nav-link <?= $isActive('/manage/vendors') ?>" href="<?= url('/manage/vendors') ?>"><i class="bi bi-truck"></i><span>Vendors</span></a><?php endif; ?>

      <?php if($can('invoice.view','payment.view')): ?><div class="nav-section">Finance</div><?php endif; ?>
      <?php if(Auth::can('invoice.view')): ?><a class="nav-link <?= $isActive('/invoices') ?>" href="<?= url('/invoices') ?>"><i class="bi bi-receipt"></i><span>Invoices & AR</span></a><?php endif; ?>

      <?php if($can('report.view','portal.manage','user.view','settings.manage','audit.view','api.manage')): ?><div class="nav-section">Management</div><?php endif; ?>
      <?php if(Auth::can('report.view')): ?><a class="nav-link <?= $isActive('/reports') ?>" href="<?= url('/reports') ?>"><i class="bi bi-bar-chart"></i><span>Reports & Analytics</span></a><?php endif; ?>
      <?php if(Auth::can('portal.manage')): ?><a class="nav-link <?= $isActive('/portal-users') ?>" href="<?= url('/portal-users') ?>"><i class="bi bi-person-badge"></i><span>Customer Portal Users</span></a><?php endif; ?>
      <?php if(Auth::can('user.view')): ?><a class="nav-link <?= $isActive('/users') ?>" href="<?= url('/users') ?>"><i class="bi bi-person-lock"></i><span>Users & Roles</span></a><?php endif; ?>
      <?php if(Auth::can('settings.manage')): ?><a class="nav-link <?= $isActive('/manage/branches') ?>" href="<?= url('/manage/branches') ?>"><i class="bi bi-diagram-3"></i><span>Branches</span></a><?php endif; ?>
      <?php if(Auth::can('settings.manage')): ?><a class="nav-link <?= $isActive('/import') ?>" href="<?= url('/import') ?>"><i class="bi bi-file-earmark-arrow-up"></i><span>Import Center</span></a><?php endif; ?>
      <?php if($can('audit.view','api.manage','settings.manage')): ?><a class="nav-link <?= $isActive('/tools') ?>" href="<?= url('/tools') ?>"><i class="bi bi-wrench-adjustable-circle"></i><span>System Tools</span></a><?php endif; ?>
      <?php if(Auth::can('settings.manage')): ?><a class="nav-link <?= $isActive('/settings') ?>" href="<?= url('/settings') ?>"><i class="bi bi-gear"></i><span>Business Settings</span></a><?php endif; ?>
    <?php endif; ?>
  </nav>
  <div class="sidebar-footer"><small>ServicePro SaaS</small><span>Field service operations</span></div>
</aside>
<div class="sidebar-backdrop" id="sidebarBackdrop"></div>
<main class="main">
  <header class="topbar">
    <div class="topbar-left"><button class="btn topbar-icon d-lg-none" id="menuBtn" type="button"><i class="bi bi-list"></i></button><div><h1><?= e($title ?? '') ?></h1><p><?= e(date('l, d F Y')) ?> · <?= e(date_default_timezone_get()) ?></p></div></div>
    <div class="topbar-tools">
      <?php if(!Auth::isPlatformAdmin()): ?><form action="<?= url('/search') ?>" method="get" class="global-search d-none d-xl-flex"><i class="bi bi-search"></i><input name="q" value="<?= e($_GET['q']??'') ?>" placeholder="Search customer, job, invoice…" autocomplete="off"></form><?php endif; ?>
      <button class="btn topbar-icon" id="themeToggle" type="button" title="Theme"><i class="bi bi-moon-stars"></i></button>
      <?php if(!Auth::isPlatformAdmin() && Auth::can('notification.view')): ?><a class="btn topbar-icon position-relative" href="<?= url('/notifications') ?>" title="Notifications"><i class="bi bi-bell"></i></a><?php endif; ?>
      <div class="user-box"><a href="<?= url('/profile') ?>" class="text-decoration-none"><span class="avatar"><?= e(strtoupper(substr($user['name']??'U',0,1))) ?></span></a><div><strong><?= e($user['name']??'') ?></strong><small><?= e($user['email']??'') ?></small></div><form method="post" action="<?= url('/logout') ?>"><?= csrf_field() ?><button class="btn btn-sm btn-outline-secondary" title="Logout"><i class="bi bi-box-arrow-right"></i></button></form></div>
    </div>
  </header>
  <?php if($msg=Session::consume('success')): ?><div class="alert alert-success alert-dismissible fade show"><i class="bi bi-check-circle me-2"></i><?= e($msg) ?><button class="btn-close" data-bs-dismiss="alert"></button></div><?php endif; ?>
  <?php if($msg=Session::consume('error')): ?><div class="alert alert-danger alert-dismissible fade show"><i class="bi bi-exclamation-triangle me-2"></i><?= e($msg) ?><button class="btn-close" data-bs-dismiss="alert"></button></div><?php endif; ?>
  <?= $content ?>
</main></div>
<div class="modal fade" id="collaborationModal"><div class="modal-dialog modal-lg"><div class="modal-content"><div class="modal-header"><h5>Comments & Documents</h5><button class="btn-close" data-bs-dismiss="modal"></button></div><div class="modal-body"><div class="row g-4"><div class="col-md-6"><form id="collabCommentForm" class="ajax-form" method="post" data-no-reload="1"><?= csrf_field() ?><label class="form-label">Internal Comment</label><textarea class="form-control" name="body" rows="3" placeholder="Add operational note; mention colleagues with @email@example.com" required></textarea><button class="btn btn-primary btn-sm mt-2">Add Comment</button></form><div id="collabComments" class="mt-3"></div></div><div class="col-md-6"><form id="collabDocumentForm" class="ajax-form" method="post" enctype="multipart/form-data" data-no-reload="1"><?= csrf_field() ?><label class="form-label">Attachment</label><select class="form-select mb-2" name="category"><option>Contract</option><option>Quotation</option><option>Invoice</option><option>Service Report</option><option>Certificate</option><option>Manual</option><option selected>Other</option></select><input class="form-control" type="file" name="file" required><button class="btn btn-primary btn-sm mt-2">Upload</button></form><div id="collabDocuments" class="mt-3"></div></div></div></div></div></div></div>
<div class="modal fade" id="metadataModal"><div class="modal-dialog"><form class="modal-content ajax-form" method="post" id="metadataForm"><?= csrf_field() ?><div class="modal-header"><h5>Custom Fields & Tags</h5><button class="btn-close" data-bs-dismiss="modal"></button></div><div class="modal-body"><div id="metadataFields"></div><hr><label class="form-label">Tags</label><div id="metadataTags" class="d-flex flex-wrap gap-2"></div></div><div class="modal-footer"><button class="btn btn-light" type="button" data-bs-dismiss="modal">Cancel</button><button class="btn btn-primary">Save Metadata</button></div></form></div></div>
<?php endif; ?>
<script>window.APP={baseUrl:<?= json_encode(rtrim(config('url'),'/')) ?>,csrf:<?= json_encode(Csrf::token()) ?>,env:<?= json_encode(config('env')) ?>};</script>
<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
<script src="https://cdn.datatables.net/2.1.8/js/dataTables.min.js"></script>
<script src="https://cdn.datatables.net/2.1.8/js/dataTables.bootstrap5.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.7/dist/chart.umd.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/fullcalendar@6.1.15/index.global.min.js"></script>
<script src="<?= url('/assets/js/app.js') ?>"></script>
</body></html>
