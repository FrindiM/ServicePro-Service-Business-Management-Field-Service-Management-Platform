<div class="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3">
 <div><a href="<?= url('/manage/contracts') ?>" class="text-decoration-none">← Contracts</a><h2 class="h4 mt-2 mb-0"><?= e($contract['contract_number']) ?></h2><p class="text-secondary mb-0"><?= e($contract['customer_name']) ?> · <?= e($contract['start_date']) ?> – <?= e($contract['end_date']) ?></p></div>
 <span class="status-badge"><?= e($contract['status']) ?></span>
</div>
<div class="card-panel">
 <div class="panel-head"><div><h3>Covered Assets</h3><p>Pilih equipment customer yang termasuk dalam coverage kontrak.</p></div></div>
 <form class="ajax-form" method="post" action="<?= url('/contracts/'.$contract['id'].'/assets') ?>"><?= csrf_field() ?>
  <div class="table-responsive"><table class="table align-middle"><thead><tr><th style="width:60px">Cover</th><th>Asset</th><th>Category</th><th>Brand / Model</th><th>Serial</th><th>Status</th></tr></thead><tbody>
   <?php foreach($assets as $a): ?><tr><td><input class="form-check-input" type="checkbox" name="assets[]" value="<?= $a['id'] ?>" <?= in_array((int)$a['id'],$selected,true)?'checked':'' ?>></td><td><strong><?= e($a['asset_code']) ?></strong></td><td><?= e($a['category']??'-') ?></td><td><?= e(trim(($a['brand']??'').' '.($a['model']??''))?:'-') ?></td><td><?= e($a['serial_number']??'-') ?></td><td><span class="status-badge"><?= e($a['status']) ?></span></td></tr><?php endforeach; ?>
   <?php if(!$assets): ?><tr><td colspan="6" class="text-center text-secondary py-4">Customer belum memiliki asset.</td></tr><?php endif; ?>
  </tbody></table></div>
  <div class="d-flex justify-content-end"><button class="btn btn-primary"><i class="bi bi-check2-circle"></i> Save Coverage</button></div>
 </form>
</div>
