PHEDEX.namespace('PHEDEX.Module');
PHEDEX.Module.PreviewRequestData = function(sandbox,string) {
  var _sbx  = sandbox,
      Dom   = YAHOO.util.Dom,
      Event = YAHOO.util.Event,
      NUtil = PHEDEX.Nextgen.Util,
      Icon  = PHEDEX.Util.icon;
  Yla(this,new PHEDEX.DataTable(_sbx,string));

  log('Nextgen: creating a genuine "'+string+'"','info',string);

  _construct = function(obj) {
    return {
      options: { },
      decorators: [
        {
          name: 'ContextMenu',
          source:'component-contextmenu'
        },
        {
          name: 'cMenuButton',
          source:'component-splitbutton',
          payload:{
            name:'Show all fields',
            map: {
              hideColumn:'addMenuItem'
            },
            container: 'control'
          }
        }
      ],
      meta: {
        table: { columns: [{ key:'level',         label:'Level',    className:'align-left' },
                           { key:'item',          label:'Item',     className:'align-left' },
                           { key:'files',         label:'Files',    className:'align-right', parser:'number' },
                           { key:'bytes',         label:'Bytes',    className:'align-right', parser:'number', formatter:'customBytes' },
                           { key:'dbs',           label:'DBS',      className:'align-left' },
                           { key:'replicas',      label:'Replicas', className:'align-left' },
                           { key:'comment',       label:'Comment',  className:'align-left' }],
            nestedColumns:[{ key:'node',          label:'Node',     className:'align-left' },
                           { key:'b_files',       label:'Files',    className:'align-right', parser:'number' },
                           { key:'b_bytes',       label:'Bytes',    className:'align-right', parser:'number', formatter:'customBytes' },
                           { key:'is_subscribed', label:'Subscribed' },
                           { key:'is_custodial',  label:'Custodial' },
                           { key:'is_move',       label:'Move' },
                           { key:'time_start',    label:'Start time',  formatter:'UnixEpochToUTC', parser:'number' },
                           { key:'subs_level',    label:'Subscription level', className:'align-leftx' }]
                },
        hide:[],
        sort:{ field:'Item' }
      },
      setSummary: function(status, text) {
        var dom = this.dom;
        if ( typeof(dom.title.innerHTML) != 'undefined' ) {
          dom.title.innerHTML = text;
        } else {
          _sbx.notify(this.id,'setSummary',status,text);
        }
      },
      _processData: function(preview) {
        var dom=this.dom, context=this.context, api=context.api, Table=[], Row, Nested, unique=0, showDBS=false, showComment=false, dbs=context.args.dbs, column, elList, oCallback,
            t=this.meta.table, cDef, i, j, item, src_info, tFiles=0, tBytes=0, text, type=context.args.type, state,
            summary={}, s, node, time_start, isRequired={}, unknown=0, known=0, excessNodes, nExcessNodes=0, tmp;

        i = t.columns.length;
        if (!t.map) { t.map = {}; }
        Dom.removeClass(dom.preview,'phedex-invisible');

        if ( !preview ) {
          this.setSummary('error','Error retrieving information from the data-service');
          return;
        }
        if ( preview.comment ) {
          this.setSummary('OK',preview.comment);
          return;
        }
        for (i in context.args.node ) {
          isRequired[context.args.node[i]] = true;
        }
//      Build the datatable and the information for per-node summaries
        for (i in preview) {
          item = preview[i];
          Row = { level:item.level, item:item[item.level.toLowerCase()] || item.item, files:item.files, bytes:item.bytes, dbs:item.dbs, comment:item.comment };
          if ( item.level == 'User Search' ) { unknown++; }
          else { known++; }

          tFiles += parseInt(item.files) || 0;
          tBytes += parseInt(item.bytes) || 0;
          tmp = [];
          for ( j in item.src_info ) { tmp.push(j); }
          tmp = tmp.sort();
          while ( j = tmp.shift() ) { // produce individual entries,plus summary matrix
            src_info = item.src_info[j];
            text = node = src_info.node;
            if ( !summary[node] ) {
              summary[node] = { empty:0, incomplete:0, subscribed:0, OK:0, isRequired:isRequired[node] };
            }
            s = summary[node];

            if ( item.files == 0 ) { // empty items are OK by definition (!)
              s.OK++;
            } else {                         // item is not empty
              if ( src_info.files == '-' ) { // replica is empty
                text += ', empty';
                s.empty++;
              } else if ( src_info.files == item.files )  { // replica is incomplete
                s.OK++;
              } else {                       // replica is (currently) complete
                text += ', incomplete';
                s.incomplete++;
              }
            }
            if ( src_info.is_subscribed == 'n' ) {
              text += ', not subscribed';
              if ( type == 'xfer' && s.isRequired ) { text = "<div class='phedex-cell-liner phedex-box-green'>" + text + "</div>"; }
            } else {
              s.subscribed++;
              if ( type == 'xfer' && s.isRequired ) { text = "<div class='phedex-cell-liner phedex-box-yellow'>" + text + "</div>"; }
            }
            if ( type == 'delete' ) {
              if ( s.isRequired ) {
                if ( src_info.files == '-' && src_info.subscribed == 'n' ) { text = "<div class='phedex-cell-liner phedex-box-red'>" + text + "</div>"; }
                else {
                  text = "<div class='phedex-cell-liner phedex-box-green'>" + text + "</div>";
                }
              }
            }

            if ( Row.replicas ) { Row.replicas += '<br/>' + text; }
            else { Row.replicas = text; }
          }
          if ( Row.comment ) {
            showComment = true;
          }
          if ( item.dbs == dbs ) {
            Row.dbs = "<span class='phedex-silver'>" + Row.dbs + "</span>";
          } else {
            showDBS = true;
          }
          Row.uniqueid = unique++;
          Nested = [];
          for (j in item.src_info ) {
            src_info = item.src_info[j];
            Nested.push({ node:src_info.node,
                          b_files:src_info.files,
                          b_bytes:src_info.bytes,
                          is_subscribed:src_info.is_subscribed,
                          is_custodial:src_info.is_custodial,
                          is_move:src_info.is_move,
                          time_start:src_info.time_start,
                          subs_level:src_info.subs_level
                         });
          }
          if ( Nested.length > 0 ) {
            Row.nesteddata = Nested;
          }
          Table.push(Row);
        }

//      Build the global summary
        text = '';
        if ( known ) {
          if ( known == 1 ) {
            text = 'One data-item matches your request';
          } else {
            text = known+' data-items match your request';
          }
          text += ', with '+tFiles+' file';
          if ( tFiles != 1 ) { text += 's'; }
          if ( tFiles ) {
            text += ', ' + ( tBytes ? PxUf.bytes(tBytes) : '0') + ' byte';
            if ( tBytes != 1 ) { text += 's'; }
          }
          text += ' in total';
        }

//      Most severe errors first...
        if ( this.re_evaluate_request ) {
          if ( !unknown && !dom.data_items.value.match(/\*/) && this.getRadioValues(this.re_evaluate_request) == 'y') {
            text += '<br/>'+Icon.Error+'All items were matched & there are no wildcards, so <strong>re-evaluating</strong> makes no sense';
          }
        }
        if ( unknown ) {
          if ( text ) { text += '<br/>'; }
          text += Icon.Warn+unknown+' item';
          if ( unknown > 1 ) { text += 's'; }
          text += ' did not match anything known to PhEDEx';
        }
        time_start=context.args.time_start;
        if ( tBytes == 0 ) {
          if ( time_start ) {
           if ( time_start > new Date().getTime()/1000 ) {
             text += '<br/>'+Icon.Warn+'The specified start-time (' + PxUf.UnixEpochToUTC(time_start) + ') is in the future, no currently existing data will match it.';
           } else {
             text += '<br/>'+Icon.Warn+'No data injected since the time you specified (' + PxUf.UnixEpochToUTC(time_start) + ')';
            }
            state = 'warn';
          } else {
            text = Icon.Error+'No data found matching your selection';
            state = 'error';
          }
          text += '<br/>If you expect data to be injected later on, you can continue with this request. Otherwise, please modify it.';
          this.setSummary(state,text);
          return;
        }

        if ( time_start ) {
          text += '<br/>'+Icon.Warn+'You will only receive data injected after '+PxUf.UnixEpochToUTC(time_start);
        }

        j=true;
        for (node in summary) {
          s = summary[node];
          if ( !s.isRequired ) {
            delete summary[node];
            continue;
          }
          if ( s.subscribed == known ) {
            if ( j ) {
              if ( type == 'xfer' ) {
                text += "<br/>"+Icon.Warn+"All matched items are already subscribed to <strong>"+node+"</strong>";
                excessNodes = node;
                nExcessNodes = 1;
              } else {
                text += '<br/>'+Icon.OK+'All matched items are subscribed to <strong>'+node+'</strong>';
              }
              j=false;
            } else {
              text += ', <strong>'+node+'</strong>';
              if ( type == 'xfer' ) { excessNodes += ' '+node; nExcessNodes++; }
            }
            delete summary[node];
            delete isRequired[node];
          }
        }
        if ( nExcessNodes ) {
          text += " <a href='#' id='_phedex_remove_excess_nodes' onclick=\"PxS.notify('"+this.id+"','suppressExcessNodes','"+excessNodes+"')\" >(remove " +
                  (nExcessNodes == 1 ? "this node" : "these nodes" ) + ")</a>";
        }
        j=true;
        for (node in summary) {
          s = summary[node];
          if ( s.OK == known ) {
            if ( j ) {
              text += '<br/>'+Icon.OK+'All matched items have replicas at <strong>'+node+'</strong>';
              j=false;
            } else {
              text += ', <strong>'+node+'</strong>';
            }
            delete summary[node];
            delete isRequired[node];
          }
        }

        if ( type == 'xfer' ) {
          j=true;
          for (node in summary) {
            s = summary[node];
            if ( s.subscribed ) {
              if ( j ) {
                text += '<br/>'+Icon.Warn+'Some items are already subscribed to <strong>'+node+'</strong>';
                j=false;
              } else {
                text += ', <strong>'+node+'</strong>';
              }
              delete summary[node];
              delete isRequired[node];
            }
          }
        }

        j=true;
        for (node in summary) {
          if ( j ) {
            if ( type == 'xfer' ) {
              text += '<br/>'+Icon.Warn+'Some items already have replicas at <strong>'+node+'</strong>';
            } else {
              text += '<br/>'+Icon.Warn+'Only some items have replicas at <strong>'+node+'</strong>';
            }
            j=false;
          } else {
            text += ', <strong>'+node+'</strong>';
          }
          delete summary[node];
          delete isRequired[node];
        }

        if ( type == 'delete' ) {
          j=true;
          for (node in isRequired) {
            if ( j ) {
              text += '<br/>'+Icon.Error+'No items have replicas at <strong>'+node+'</strong>';
              j=false;
              excessNodes = node;
              nExcessNodes = 1;
            } else {
              text += ', <strong>'+node+'</strong>';
              excessNodes += ' '+node;
              nExcessNodes++;
            }
          }
          if ( nExcessNodes ) {
            text += " <a href='#' id='_phedex_remove_excess_nodes' onclick=\"PxS.notify('"+this.id+"','suppressExcessNodes','"+excessNodes+"')\" >(remove " +
                    (nExcessNodes == 1 ? "this node" : "these nodes" ) + ")</a>";
          }
        }
        text += '<br>';
        this.setSummary('OK',text);

        if ( !showDBS )     { this.meta.hide['DBS'] = 1; }
        if ( !showComment ) { this.meta.hide['Comment'] = 1; }
        this.setSummary('OK',text);

// TW Need to uncomment this later?
//         this.needProcess = false;
        return Table;
      },

      initData: function() {
        if ( this.args ) {
          _sbx.notify( this.id, 'initData' );
          return;
        }
        _sbx.notify( 'module', 'needArguments', this.id );
      },

      setArgs: function(arr) {
        this.args = arr;
        _sbx.notify(this.id,'setArgs');
      },
      getData: function() {
        if ( !this.args ) {
          this.initData();
          return;
        }
        log('Fetching data','info',this.me);
        _sbx.notify( this.id, 'getData', { api:'previewrequestdata', args:this.args } );
      },
      gotData: function(data,context,response) {
        PHEDEX.Datasvc.throwIfError(data,response);
        log('Got new data','info',this.me);
        if ( !data.preview ) {
          throw new Error('data incomplete for '+context.api);
        }
        this.data = data.preview;
        this.context = context;
        this.fillDataSource(this.data);
        _sbx.notify( this.id, 'gotData' );
      },
     }
  };
  Yla(this,_construct(this),true);
  return this;
};

log('loaded...','info','previewrequestdata');