(function($){
  'use strict';
  const app=window.APP||{baseUrl:'',csrf:''};
  const base=String(app.baseUrl||'').replace(/\/$/,'');
  const toast=(message,type='success')=>{
    if(window.Swal){Swal.fire({toast:true,position:'top-end',icon:type,title:message,showConfirmButton:false,timer:2200,timerProgressBar:true});}
    else alert(message);
  };
  const fail=(xhr)=>{
    const json=xhr?.responseJSON||{};
    let message=json.message||'Unable to process request.';
    if(json.errors&&typeof json.errors==='object') message+='\n'+Object.values(json.errors).flat().join('\n');
    if(window.Swal) Swal.fire({icon:'error',title:'Request failed',text:message}); else alert(message);
  };
  const post=(url,data={})=>$.ajax({url,method:'POST',data:Object.assign({_token:app.csrf},data),headers:{Accept:'application/json'}});

  // Mobile sidebar.
  const $sidebar=$('#sidebar'),$backdrop=$('#sidebarBackdrop');
  function sidebar(open){$sidebar.toggleClass('open',open);$backdrop.toggleClass('show',open);$('body').toggleClass('sidebar-open',open);}
  $('#menuBtn').on('click',()=>sidebar(true)); $('#sidebarClose,#sidebarBackdrop').on('click',()=>sidebar(false));

  // User theme preference.
  $('#themeToggle').on('click',function(){
    const current=document.documentElement.getAttribute('data-bs-theme')||'light',next=current==='dark'?'light':'dark';
    document.documentElement.setAttribute('data-bs-theme',next); localStorage.setItem('servicepro-theme',next);
    $(this).find('i').attr('class',next==='dark'?'bi bi-sun':'bi bi-moon-stars');
  });
  if(document.documentElement.getAttribute('data-bs-theme')==='dark') $('#themeToggle i').attr('class','bi bi-sun');

  // Data tables are progressive enhancement; page remains usable if CDN is unavailable.
  if($.fn.DataTable){$('.datatable').each(function(){if(!$.fn.DataTable.isDataTable(this)) new DataTable(this,{pageLength:25,order:[],responsive:false,language:{search:'Search:',lengthMenu:'Show _MENU_',info:'_START_–_END_ of _TOTAL_'}});});}

  // Standard AJAX forms, including multipart uploads.
  $(document).on('submit','.ajax-form',function(e){
    e.preventDefault();
    const form=this,$f=$(form),$btn=$f.find('[type=submit],button:not([type])').last(),hasFile=$f.attr('enctype')==='multipart/form-data'||$f.find('input[type=file]').length>0;
    $btn.prop('disabled',true).data('old-html',$btn.html()).html('<span class="spinner-border spinner-border-sm me-1"></span>Saving…');
    const options={url:$f.attr('action')||location.href,method:($f.attr('method')||'POST').toUpperCase(),headers:{Accept:'application/json'}};
    if(hasFile){options.data=new FormData(form);options.processData=false;options.contentType=false;}else options.data=$f.serialize();
    $.ajax(options).done(r=>{
      if(r && r.success===false){toast(r.message||'Unable to process request.','error');return;}
      toast(r?.message||'Saved successfully.');
      if(r?.redirect){setTimeout(()=>location.href=r.redirect,350);return;}
      if($f.data('no-reload')) return;
      setTimeout(()=>location.reload(),350);
    }).fail(fail).always(()=>{$btn.prop('disabled',false).html($btn.data('old-html')||'Save');});
  });

  // Lightweight button actions.
  $(document).on('click','.ajax-action',function(e){
    e.preventDefault(); const $b=$(this); let payload={};
    try{payload=JSON.parse($b.attr('data-payload')||'{}');}catch(_e){}
    $b.prop('disabled',true);
    post($b.data('url'),payload).done(r=>{toast(r?.message||'Action completed.');if(r?.redirect)setTimeout(()=>location.href=r.redirect,250);else setTimeout(()=>location.reload(),300);}).fail(fail).always(()=>$b.prop('disabled',false));
  });

  // Legacy controls.
  $(document).on('change','.job-status',function(){post(base+'/jobs/'+$(this).data('id')+'/status',{status:this.value}).fail(fail);});
  $(document).on('click','.tenant-status',function(){const $b=$(this);post(base+'/platform/tenants/'+$b.data('id')+'/status',{status:$b.data('status')}).done(()=>location.reload()).fail(fail);});

  // Generic module editor/delete.
  $(document).on('click','[data-module-new]',function(){const form=document.querySelector('#moduleModal form');if(form){form.reset();$(form).find('[name=id]').val('');}});
  $(document).on('click','.module-edit',function(){
    const form=document.querySelector('#moduleModal form'); if(!form)return;
    let row={}; try{row=JSON.parse(atob($(this).data('record')));}catch(e){return fail({responseJSON:{message:'Unable to read record.'}});}
    form.reset(); Object.entries(row).forEach(([k,v])=>{$(form).find('[name="'+CSS.escape(k)+'"]').val(v??'');});
    bootstrap.Modal.getOrCreateInstance(document.getElementById('moduleModal')).show();
  });
  $(document).on('click','.module-delete',function(){const $b=$(this);const go=()=>post($b.data('url')).done(()=>location.reload()).fail(fail);if(window.Swal)Swal.fire({icon:'warning',title:'Delete this record?',text:'The record will be soft-deleted when supported.',showCancelButton:true,confirmButtonText:'Delete'}).then(r=>{if(r.isConfirmed)go();});else if(confirm('Delete this record?'))go();});

  // Customer/site/asset dependent selects.
  function filterRelational($select){const p=$select.data('parent'),v=$(p).val();$select.find('option[data-parent-value]').each(function(){$(this).prop('hidden',v&&String($(this).data('parent-value'))!==String(v));});if($select.find('option:selected').prop('hidden'))$select.val('');}
  $('.relational-select').each(function(){filterRelational($(this));});
  $(document).on('change','#requestCustomer',()=>$('.relational-select').each(function(){filterRelational($(this));}));

  // Reusable dynamic line items for quotations, purchase and invoices.
  function reindexRows($container){$container.children('tr').each(function(i){$(this).find('[data-name]').each(function(){this.name='items['+i+']['+$(this).data('name')+']';});});}
  function addQuoteRow(){const tpl=document.getElementById('quoteItemTpl');if(!tpl)return;const $body=$('#quoteItemBody');$body.append(tpl.content.cloneNode(true));reindexRows($body);}
  $('#addQuoteItem').on('click',addQuoteRow); if($('#quoteItemBody').length&&!$('#quoteItemBody tr').length)addQuoteRow();
  $(document).on('click','.remove-row',function(){$(this).closest('tr').remove();reindexRows($(this).closest('tbody'));});

  let purchaseItems=[]; try{purchaseItems=JSON.parse($('#purchaseItemData').text()||'[]');}catch(_e){}
  function itemOptions(){return '<option value="">Select item</option>'+purchaseItems.map(i=>'<option value="'+i.id+'">'+escapeHtml((i.sku||'')+' · '+(i.item_name||''))+'</option>').join('');}
  function addPurchaseRow(type){const id=type==='pr'?'#prItems':'#poItems',$c=$(id),i=$c.children().length;let html='<tr><td><select class="form-select" data-name="item_id" required>'+itemOptions()+'</select></td><td><input class="form-control" data-name="description"></td><td><input class="form-control" type="number" step="0.01" min="0.01" value="1" data-name="quantity" required></td>'+(type==='po'?'<td><input class="form-control" type="number" step="0.01" min="0" value="0" data-name="unit_price"></td>':'')+'<td><button class="btn btn-sm btn-light text-danger remove-row" type="button"><i class="bi bi-trash"></i></button></td></tr>';$c.append(html);reindexRows($c);}
  $(document).on('click','[data-add-row="pr"],[data-add-row="po"]',function(){addPurchaseRow($(this).data('add-row'));});
  if($('#prItems').length&&!$('#prItems tr').length)addPurchaseRow('pr'); if($('#poItems').length&&!$('#poItems tr').length)addPurchaseRow('po');

  function addInvoiceRow(){const $c=$('#invoiceItems');if(!$c.length)return;$c.append('<tr><td><input class="form-control" data-name="description" required></td><td><input class="form-control" type="number" step="0.01" min="0.01" value="1" data-name="quantity"></td><td><input class="form-control" value="unit" data-name="unit"></td><td><input class="form-control" type="number" step="0.01" min="0" value="0" data-name="unit_price"></td><td><input class="form-control" type="number" step="0.01" min="0" value="0" data-name="discount"></td><td><input class="form-control" type="number" step="0.01" min="0" value="0" data-name="tax"></td><td><button class="btn btn-sm btn-light text-danger remove-row" type="button"><i class="bi bi-trash"></i></button></td></tr>');reindexRows($c);}
  $(document).on('click','[data-add-row="invoice"]',addInvoiceRow); if($('#invoiceItems').length&&!$('#invoiceItems tr').length)addInvoiceRow();

  // PO receiving.
  $(document).on('click','.receive-po',function(){const id=$(this).data('id');$('#receivePoName').text('Receive '+$(this).data('number'));$('#receiveForm').attr('action',base+'/purchasing/orders/'+id+'/receive');bootstrap.Modal.getOrCreateInstance(document.getElementById('receiveModal')).show();});

  // Role assignment.
  $(document).on('click','.assign-role',function(){$('#assignRoleName').text('Assign role to '+$(this).data('name'));$('#assignRoleForm').attr('action',base+'/users/'+$(this).data('id')+'/role');bootstrap.Modal.getOrCreateInstance(document.getElementById('assignRoleModal')).show();});

  // Job material warehouse metadata.
  $('#stockSelect').on('change',function(){const o=$(this).find(':selected');$('#materialItem').val(o.data('item')||this.value);$('#materialWarehouse').val(o.data('warehouse')||'');}).trigger('change');

  // GPS check-in: graceful failure by design.
  $('#checkinModal').on('shown.bs.modal',function(){const $f=$(this).find('form'),$s=$f.find('.geo-status');$s.attr('class','geo-status alert alert-info').text('Requesting location…');if(!navigator.geolocation){$s.attr('class','geo-status alert alert-warning').text('GPS is unavailable. You may still check in.');return;}navigator.geolocation.getCurrentPosition(p=>{$f.find('[name=latitude]').val(p.coords.latitude);$f.find('[name=longitude]').val(p.coords.longitude);$s.attr('class','geo-status alert alert-success').text('Location captured (accuracy ±'+Math.round(p.coords.accuracy)+' m).');},()=>{$s.attr('class','geo-status alert alert-warning').text('Location permission unavailable. Check-in will continue with a warning.');},{enableHighAccuracy:true,timeout:8000,maximumAge:30000});});

  // Signature pad without an external dependency.
  $('.signature-pad').each(function(){const canvas=this,ctx=canvas.getContext('2d');let drawing=false,last=null;function pos(e){const r=canvas.getBoundingClientRect(),p=e.touches?e.touches[0]:e;return{x:(p.clientX-r.left)*(canvas.width/r.width),y:(p.clientY-r.top)*(canvas.height/r.height)}}function start(e){drawing=true;last=pos(e);e.preventDefault()}function move(e){if(!drawing)return;const p=pos(e);ctx.lineWidth=2.2;ctx.lineCap='round';ctx.strokeStyle=getComputedStyle(document.documentElement).getPropertyValue('--sp-ink')||'#172033';ctx.beginPath();ctx.moveTo(last.x,last.y);ctx.lineTo(p.x,p.y);ctx.stroke();last=p;e.preventDefault()}function end(){drawing=false;last=null}canvas.addEventListener('pointerdown',start);canvas.addEventListener('pointermove',move);window.addEventListener('pointerup',end);canvas.addEventListener('touchstart',start,{passive:false});canvas.addEventListener('touchmove',move,{passive:false});canvas.addEventListener('touchend',end);$(canvas).closest('form').on('submit',function(){if(!$(this).find('[name=signature_data]').val())$(this).find('[name=signature_data]').val(canvas.toDataURL('image/png'));});$(canvas).closest('form').find('.clear-signature').on('click',()=>{ctx.clearRect(0,0,canvas.width,canvas.height);$(canvas).closest('form').find('[name=signature_data]').val('');});});

  // FullCalendar schedule.
  const calEl=document.getElementById('fullCalendar');
  if(calEl&&window.FullCalendar){const cal=new FullCalendar.Calendar(calEl,{initialView:window.innerWidth<768?'listWeek':'dayGridMonth',headerToolbar:{left:'prev,next today',center:'title',right:'dayGridMonth,timeGridWeek,timeGridDay,listWeek'},events:calEl.dataset.eventsUrl,height:'auto',eventClick:i=>{if(i.event.url){i.jsEvent.preventDefault();location.href=i.event.url;}}});cal.render();}

  // Analytics charts.
  if(window.Chart){document.querySelectorAll('.report-chart').forEach(el=>{let labels=[],values=[];try{labels=JSON.parse(el.dataset.labels||'[]');values=JSON.parse(el.dataset.values||'[]');}catch(_e){}new Chart(el,{type:el.dataset.type||'bar',data:{labels,datasets:[{label:el.closest('.card-panel')?.querySelector('h3')?.textContent||'Value',data:values,borderWidth:2,tension:.3,fill:false}]},options:{responsive:true,plugins:{legend:{display:false}},scales:{y:{beginAtZero:true}}}});});}





  // Technician skill matrix editor.
  $(document).on('click','.tech-skills-btn',function(){const id=$(this).data('id');$.getJSON(base+'/technicians/'+id+'/skills').done(r=>{const d=r.data||{};$('#techSkillsTitle').text('Skills · '+(d.technician?.name||'Technician'));$('#techSkillsForm').attr('action',base+'/technicians/'+id+'/skills');$('#techSkillsBody').html((d.skills||[]).map(x=>'<div class="d-flex align-items-center gap-2 mb-2"><label class="form-check flex-grow-1"><input class="form-check-input me-2" type="checkbox" name="skills['+x.id+']" value="'+(x.level||3)+'" '+(x.level>0?'checked':'')+'>'+escapeHtml(x.name)+'</label><select class="form-select form-select-sm skill-level" style="width:95px" data-skill="'+x.id+'"><option value="1">Lv 1</option><option value="2">Lv 2</option><option value="3">Lv 3</option><option value="4">Lv 4</option><option value="5">Lv 5</option></select></div>').join(''));(d.skills||[]).forEach(x=>$('#techSkillsBody .skill-level[data-skill="'+x.id+'"]').val(x.level||3));bootstrap.Modal.getOrCreateInstance(document.getElementById('techSkillsModal')).show();}).fail(fail);});
  $(document).on('change','.skill-level',function(){const id=$(this).data('skill');$('#techSkillsBody input[name="skills['+id+']"]').val(this.value).prop('checked',true);});

  // Generic custom-field/tag metadata editor.
  $(document).on('click','.metadata-btn',function(){
    const entity=$(this).data('entity'),id=$(this).data('id'),$form=$('#metadataForm');
    $form.attr('action',base+'/metadata/'+entity+'/'+id);$('#metadataFields').html('<div class="text-secondary">Loading…</div>');$('#metadataTags').empty();
    $.getJSON(base+'/metadata/'+entity+'/'+id).done(r=>{const data=r.data||{},selected=new Set((data.tags||[]).map(x=>String(x.id)));let html='';(data.fields||[]).forEach(f=>{const type=f.field_type==='number'?'number':(f.field_type==='date'?'date':'text');html+='<label class="form-label">'+escapeHtml(f.label)+(f.required?' *':'')+'</label><input class="form-control mb-2" type="'+type+'" name="custom['+f.id+']" value="'+escapeHtml(f.value_text||'')+'" '+(f.required?'required':'')+'>';});$('#metadataFields').html(html||'<p class="text-secondary small">No custom fields configured for this entity.</p>');$('#metadataTags').html((data.all_tags||[]).map(t=>'<label class="status-badge"><input class="form-check-input me-1" type="checkbox" name="tags[]" value="'+t.id+'" '+(selected.has(String(t.id))?'checked':'')+'> '+escapeHtml(t.name)+'</label>').join('')||'<span class="text-secondary small">No tags configured.</span>');bootstrap.Modal.getOrCreateInstance(document.getElementById('metadataModal')).show();}).fail(fail);
  });

  // Lead Kanban drag & drop.
  let draggedLead=null;
  $(document).on('dragstart','.lead-card',function(){draggedLead=this;$(this).addClass('dragging');});
  $(document).on('dragend','.lead-card',function(){$(this).removeClass('dragging');$('.lead-dropzone').removeClass('drag-over');draggedLead=null;});
  $(document).on('dragover','.lead-dropzone',function(e){e.preventDefault();$(this).addClass('drag-over');});
  $(document).on('dragleave','.lead-dropzone',function(){$(this).removeClass('drag-over');});
  $(document).on('drop','.lead-dropzone',function(e){e.preventDefault();$(this).removeClass('drag-over');if(!draggedLead)return;const id=$(draggedLead).data('lead-id'),status=$(this).closest('.lead-column').data('status'),$zone=$(this);const oldParent=draggedLead.parentNode;$zone.append(draggedLead);post(base+'/leads/'+id+'/status',{status}).done(r=>toast(r?.message||'Lead moved.')).fail(x=>{oldParent.appendChild(draggedLead);fail(x);});});

  function escapeHtml(s){return String(s??'').replace(/[&<>'"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[c]));}
})(jQuery);

// Internal collaboration: comments + entity documents.
(function(){
  let collabEntity=null, collabId=null;
  function loadCollab(){
    if(!collabEntity||!collabId)return;
    $.getJSON(base+'/collab/'+encodeURIComponent(collabEntity)+'/'+collabId).done(r=>{
      const d=r.data||{},comments=d.comments||[],docs=d.documents||[];
      $('#collabComments').html(comments.length?comments.map(c=>'<div class="collab-comment"><div class="d-flex justify-content-between"><strong>'+escapeHtml(c.user_name||'User')+'</strong><small class="text-secondary">'+escapeHtml(c.created_at||'')+'</small></div><div>'+escapeHtml(c.body||'')+'</div></div>').join(''):'<small class="text-secondary">No comments yet.</small>');
      $('#collabDocuments').html(docs.length?docs.map(x=>'<div class="report-row"><span><strong>'+escapeHtml(x.file_name||'Document')+'</strong><small>'+escapeHtml((x.category||'Other')+' · '+(x.created_at||''))+'</small></span><a class="btn btn-sm btn-light" href="'+base+'/documents/'+x.id+'/download"><i class="bi bi-download"></i></a></div>').join(''):'<small class="text-secondary">No documents yet.</small>');
    }).fail(fail);
  }
  $(document).on('click','.collab-btn',function(){collabEntity=$(this).data('entity');collabId=$(this).data('id');$('#collabCommentForm').attr('action',base+'/collab/'+collabEntity+'/'+collabId+'/comments');$('#collabDocumentForm').attr('action',base+'/collab/'+collabEntity+'/'+collabId+'/documents');loadCollab();bootstrap.Modal.getOrCreateInstance(document.getElementById('collaborationModal')).show();});
  $('#collabCommentForm,#collabDocumentForm').on('ajax:done',loadCollab);
  $(document).ajaxSuccess(function(_e,xhr,settings){if(settings.url&&settings.url.includes('/collab/')&&settings.type!=='GET'){setTimeout(loadCollab,100);}});
})();
$(document).on('click','.portal-proof-btn',function(){const id=$(this).data('id'),balance=$(this).data('balance'),number=$(this).data('number');$('#portalProofForm').attr('action',base+'/portal/invoices/'+id+'/payment-proof');$('#portalProofAmount').val(balance).attr('max',balance);$('#portalProofInvoice').text(number+' · Outstanding '+balance);bootstrap.Modal.getOrCreateInstance(document.getElementById('paymentProofModal')).show();});
$(document).on('click','.subscription-edit',function(){const id=$(this).data('id');$('#subscriptionForm').attr('action',base+'/platform/tenants/'+id+'/subscription').find('[name=plan_id]').val($(this).data('plan')).end().find('[name=status]').val($(this).data('status'));bootstrap.Modal.getOrCreateInstance(document.getElementById('subscriptionModal')).show();});
$(document).on('click','.platform-feature',function(){$('#featureForm').attr('action',base+'/platform/tenants/'+$(this).data('id')+'/feature');$('#featureTenant').text($(this).data('name'));bootstrap.Modal.getOrCreateInstance(document.getElementById('featureModal')).show();});
$(document).on('click','.platform-payment',function(){$('#platformPaymentForm').attr('action',base+'/platform/tenants/'+$(this).data('id')+'/payment');$('#paymentTenant').text($(this).data('name'));bootstrap.Modal.getOrCreateInstance(document.getElementById('platformPaymentModal')).show();});
$(document).on('click','.platform-reset',function(){$('#resetAdminForm').attr('action',base+'/platform/tenants/'+$(this).data('id')+'/reset-admin');$('#resetTenant').text($(this).data('name'));bootstrap.Modal.getOrCreateInstance(document.getElementById('resetAdminModal')).show();});
$(document).on('click','.platform-delete',function(){const id=$(this).data('id'),name=$(this).data('name'),go=()=>post(base+'/platform/tenants/'+id+'/delete').done(r=>{toast(r.message);setTimeout(()=>location.reload(),250)}).fail(fail);if(window.Swal)Swal.fire({icon:'warning',title:'Archive '+name+'?',text:'Access will be disabled and subscription cancelled. Transaction data is retained for audit.',showCancelButton:true,confirmButtonText:'Archive tenant'}).then(r=>r.isConfirmed&&go());else if(confirm('Archive '+name+'?'))go();});
