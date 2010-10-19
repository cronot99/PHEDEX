PHEDEX.namespace('Component');
PHEDEX.Component.Subscribe = function(sandbox,args) {
  var _me = 'component-subscribe',
      _sbx = sandbox,
      payload, opts, obj,
      ttIds = [], ttHelp = {};

  var groupComplete =
        {
          name:'autocomp-groups',
          source:'component-autocomplete',
          payload:{
            el:      '',
            dataKey: 'group',
            api:     'groups',
            argKey:  'group',
            handler: 'buildGroupsSelector'
          }
        };

  if ( !args ) { args={}; }
  opts = {
    text: 'Make a subscription',
    payload:{
      control:{
        parent:'control',
        payload:{
          text:'Subscribe',
          animate:  false,
          disabled: false, //true,
        },
        el:'content'
      },
      buttons: [ 'Dismiss', 'Apply', 'Reset' ],
      buttonMap: {
                   Apply:{title:'Subscribe this data', action:'Validate'}
                 },
      panel: {
        Datasets:{
          fields:{
            dataset:{type:'text', dynamic:true },
          }
        },
        Blocks:{
          fields:{
            block:{type:'text', dynamic:true },
          }
        },
        Parameters:{
          fields:{
// need to extract the list of DBS's from somewhere...
            dbs:          {type:'regex', text:'Name your DBS', negatable:false, value:'test' /*http://cmsdoc.cern.ch/cms/aprom/DBS/CGIServer/query'*/ },

// node can be multiple
            node:         {type:'regex', text:'Destination node', tip:'enter a valid node name', negatable:false, value:'TX_Test1_Buffer' },
            move:         {type:'radio', fields:['replica','move'], text:'Transfer type',
                           tip:'Replicate (copy) or move the data. A "move" will delete the data from the source after it has been transferred', default:'replica' },
            static:       {type:'radio', fields:['growing','static'], text:'Subscription type',
                           tip:'A static subscription is a snapshot of the data as it is now. A growing subscription will add new blocks as they become available', default:'growing' },
            priority:     {type:'radio', fields:['low','normal','high'],  byName:true, text:'Priority', default:'low' },

            custodial:    {type:'checkbox', text:'Make custodial request?', tip:'Check this box to make the request custodial', attributes:{checked:false} },
            group:        {type:'regex',    text:'User-group', tip:'The group which is requesting the data. May be left undefined, used only for accounting purposes', negatable:false, autoComplete:groupComplete },

            time_start:   {type:'regex',    text:'Start-time for subscription',    tip:'This is valid for datasets only. Unix epoch-time', negatable:false },
            request_only: {type:'checkbox', text:'Request only, do not subscribe', tip:'Make the request without making a subscription',   attributes:{checked:true} },
            no_mail:      {type:'checkbox', text:'Suppress email notification?',   tip:'Check this box to not send an email',              attributes:{checked:true} },
            comments:     {type:'textarea', text:'Enter your comments here', className:'phedex-inner-textarea' },
          }
        }
      }
    }
  }
  Yla(args, opts);
  Yla(args.payload, opts.payload);
  payload = args.payload;
  obj = payload.obj;

//   this.id = _me+'_'+PxU.Sequence(); // don't set my own ID, inherit the one I get from the panel!
  Yla(this, new PHEDEX.Component.Panel(sandbox,args));

  this.cartHandler = function(o) {
    return function(ev,arr) {
      var action=arr[0], args=arr[1], ctl=o.ctl['panel'];
      switch (action) {
        case 'add': {
          var c, cart=o.cart, cd=cart.data, type, item, blocks, _a=o;
          type = 'dataset';
          item = args.dataset;
          if ( !cart[item] ) {
            cd[item] = { dataset:item, is_open:args.ds_is_open, blocks:{} };
          }
          blocks = cd[item].blocks;
          if ( args.block ) {
            type = 'block';
            item = args.block;
            if ( blocks[item] ) {
              return;
            }
          }
          blocks[item] = { block:item, is_open:args.is_open };
          c = o.meta._panel.fields[type];
          cart.elements.push({type:type, el:o.AddFieldsetElement(c,item)});
          if ( ctl ) { ctl.Enable(); }
          else       { YuD.removeClass(o.overlay.element,'phedex-invisible'); }
          o.ctl.Apply.set('disabled',false);
          break;
        }
      }
    }
  }(this);
  _sbx.listen('buildRequest',this.cartHandler);

/**
 * construct a PHEDEX.Component.Subscribe object. Used internally only.
 * @method _contruct
 * @private
 */
  _construct = function() {
    return {
      me: _me,
      cart:{ data:{}, elements:[] },
      _init: function(args) {
        this.selfHandler = function(o) {
          return function(ev,arr) {
            var action    = arr[0], subAction, value,
                cart = o.cart, _panel = o.meta._panel, _fieldsets = _panel.fieldsets;
            switch (action) {
              case 'Panel': {
                subAction = arr[1];
                value     = arr[2];
                switch (subAction) {
                  case 'Reset': {
                    var item, _cart, _fieldset;
                    while (item = cart.elements.shift()) {
                      _fieldset = _fieldsets[item.type].fieldset;
                      _fieldset.removeChild(item.el);
                    }
                    cart = { data:{}, elements:[] };
//                     o.ctl.Apply.set('disabled',true);
                    break;
                  }
                  case 'Apply': {
                    var args={}, i, val, cart=o.cart, iCart, item, dbs, dataset, ds, block, xml, vName, vValue;
//                     o.ctl.Apply.set('disabled',true);
                    o.dom.result.innerHTML = '';
                    for ( i in value ) {
                      val = value[i];
                      vName = val.name;
                      vValue = val.values.value;
                      if ( vName == 'dataset' || vName == 'block' ) { level = vName; }
                      else if ( vName == 'dbs' ) { dbs         = vValue; }
                      else                       { args[vName] = vValue; }
                    }
                    args.move         = (args.move   == '1') ? 'y' : 'n';
                    args.static       = (args.static == '1') ? 'y' : 'n';
                    args.no_mail      =  args.no_mail        ? 'y' : 'n';
                    args.request_only =  args.request_only   ? 'y' : 'n';
                    args.custodial    =  args.custodial      ? 'y' : 'n';

                    xml = '<data version="2.0"><dbs name="'+dbs+'">';
                    iCart=cart.data;
                    for ( dataset in iCart ) {
                      ds=iCart[dataset];
                      xml += '<dataset name="'+dataset+'" is-open="'+ds.is_open+'">';
                      for ( block in ds.blocks ) {
                        xml += '<block name="'+block+'" is-open="'+ds.blocks[block].is_open+'" />';
                      }
                      xml += '</dataset>';
                    }
                    xml += '</dbs></data>';
                    args.data = xml;
                    o.dom.result.innerHTML = 'Submitting request, please wait...';
                    _sbx.notify( o.id, 'getData', { api:'subscribe', args:args, method:'post' } );
                    break;
                  }
                }
                break;
              }
              case 'expand': { // set focus appropriately when the panel is revealed
                if ( !o.firstAlignmentDone ) {
                  o.overlay.align(this.context_el,this.align_el);
                  o.firstAlignmentDone = true;
                }
                if ( o.focusOn ) { o.focusOn.focus(); }
                break;
              }
              case 'datasvcFailure': {
                var api = arr[1][1].api,
                    msg = arr[1][0].message;
                    str = "Error when making call '"+api+"':";
                msg = msg.replace(str,'').trim();
                banner('Error subscribing data','error');
                o.dom.result.innerHTML = 'Error subscribing data:<br />'+msg;
                YuD.removeClass(o.dom.resultFieldset,'phedex-invisible');
                break;
              }
              case 'authData': {
                o.buildNodeSelector(arr[1].node);
                break;
              }
            }
          }
        }(this);
        _sbx.listen(this.id,this.selfHandler);
        _sbx.notify('ComponentExists',this); // borrow the Core machinery for getting data!

        this.reAuth = function(o) {
          return function(ev,arr) {
            var authData = arr[0];
            o.buildNodeSelector(authData.node);
          }
        }(this);
        _sbx.listen('authData',this.reAuth);
        _sbx.notify('login','getAuth',this.id);

        var fieldset = document.createElement('fieldset'),
            legend = document.createElement('legend'),
            el = document.createElement('div');
        fieldset.id = 'fieldset_'+PxU.Sequence();
        fieldset.className = 'phedex-invisible';
        legend.appendChild(document.createTextNode('Results'));
        fieldset.appendChild(legend);
//         legend.appendChild(document.createTextNode(' '));
        this.dom.panel.appendChild(fieldset);

        el.className = 'phedex-panel-status';
        fieldset.appendChild(el);
        this.dom.result = el;
        this.dom.resultFieldset = fieldset;

//         this.ctl.Apply.set('disabled',true);
      },
      buildNodeSelector: function(nodeList) {
        var nodes=[], i, nBuffer=0, nMSS=0, node, name, nNodes=nodeList.length, _buffer=[], _mss=[],
            _defaultBuffer=false, _defaultMSS=false, nodeInner, nodeCtl, nCols, nodePanel, container, el, cBox, label;
        for (i in nodeList) {
          name = nodeList[i].name;
          node = {name:name, isBuffer:false, isMSS:false, checked:false};
          if ( nNodes == 1 ) { node.checked = true; }
          if ( name.match(/_Buffer$/) ) { nBuffer++; _buffer[name]=1; node.isBuffer = true; }
          if ( name.match(/_MSS$/) )    { nMSS++;    _mss[name]=1;    node.isMSS = true; }
          nodes[name] = node;
        }

//      Now the logic to build the selector. If only one node is allowed, select it and lock it in
        nodeInner = this.meta._panel.fields['node'].inner;
        nodeCtl = nodeInner.childNodes[0];
        if ( nNodes == 1 ) {
          nodeCtl.value = nodeList[0].name;
          nodeCtl.disabled = true;
          return;
        }

//      Now, if there is one Buffer node and no MSS nodes, select that by default
        if ( nBuffer == 1 && nMSS == 0 ) { _defaultBuffer = true; }
//      if there's only one MSS node, select that by default
        if ( nMSS == 1 ) { _defaultMSS = true; }
//      if any node-types are selected by default, set that default in the nodes array
        if ( nNodes > 1 && ( _defaultBuffer || _defaultMSS ) ) {
          if ( _defaultBuffer ) {
            for (name in _buffer) {
              nodes[name].checked = true;
            }
          }
          if ( _defaultMSS ) {
            for (name in _mss) {
              nodes[name].checked = true;
            }
          }
        }

//      now build the panel to show the nodes
        nodes = nodes.sort();
        nCols = Math.round(Math.sqrt(nNodes)) + 1;
        i = 0;
        nodePanel = this.dom.nodePanel;
        if ( nodePanel ) { nodePanel.destroy(); this.nodeFocus = null; }
        nodePanel = document.createElement('div');
        nodePanel.className = 'phedex-panel-node-select phedex-invisible';
        container = document.createElement('div');
        for (name in nodes) {
          if ( i > 0 && i%nCols == 0 ) {
            nodePanel.appendChild(container);
            container = document.createElement('div');
          }
          i++;
          el = document.createElement('div');
          el.className = 'phedex-panel-select';
          cBox = document.createElement('input');
          cBox.type = 'checkbox';
          cBox.className = 'phedex-panel-checkbox';
          cBox.id = 'cbox_' + PxU.Sequence();
          cBox.checked = nodes[name].checked;
          if ( !this.nodeFocus ) { this.nodeFocus = cBox; }
          el.appendChild(cBox);
          label = document.createElement('div');
          label.className = 'phedex-inline';
          label.innerHTML = name;
          el.appendChild(label);
          container.appendChild(el);
        }
        if ( i%nCols ) { nodePanel.appendChild(container); }
        nodePanel.style.width = nCols * colWidth;
        this.nodePanel = nodePanel;
        /*document.body*/nodeInner.appendChild(nodePanel);
        nodeCtl.onfocus = function(o) {
          return function() {
            var colWidth;
//             colWidth = o.nodeFocus.parent.style.effectiveWidth;
            YuD.removeClass(o.nodePanel,'phedex-invisible');
            if ( !colWidth ) {
              colWidth = el.style.width;
            }
          }
        }(this);
        nodeCtl.onblur = function(o) {
          return function() {
            YuD.addClass(o.nodePanel,'phedex-invisible');
          }
        }(this);
      },
      showNodeSelectPanel: function() {
        debugger;
      },
      gotData: function(data,context) {
        var rid = data.request_created[0].id;
        log('Got new data: api='+context.api+', id='+context.poll_id+', magic:'+context.magic,'info',this.me);
        banner('Subscription succeeded!');
        this.dom.result.innerHTML = 'Subscription succeeded:<br/>request-ID = '+rid+'<br/>';
        YuD.removeClass(this.dom.resultFieldset,'phedex-invisible');
//         this.ctl.Apply.set('disabled',true);
      },
      getDataFail: function(api,message) {
        var str = "Error when making call '"+api+"':";
        var x = message.replace(str,'').trim();
        banner(message.replace(str,'').trim(),'error');
      }
    };
  };
  Yla(this,_construct(this),true);
  this._init(args);
  return this;
}

log('loaded...','info','component-subscribe');