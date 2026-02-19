import { LightningElement, api, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { CloseActionScreenEvent } from 'lightning/actions';

import JSPDF from '@salesforce/resourceUrl/jspdf';
import AUTOTABLE from '@salesforce/resourceUrl/jspdf_autotable';
import LOGO from '@salesforce/resourceUrl/AlameriahDLogo';

import getAssignments from '@salesforce/apex/ExecutiveReportAssignmentsLwcController.getAssignments';
import savePdfFromLwc from '@salesforce/apex/ExecutiveReportAssignmentsLwcController.savePdfFromLwc';


export default class ExecutiveReportAssignmentsPdf extends LightningElement {
  @api recordId;
  @track isLoading = false;

  _libsLoaded = false;

  async loadLibsIfNeeded() {
    if (this._libsLoaded) return;
    await loadScript(this, JSPDF);
    await loadScript(this, AUTOTABLE);
    this._libsLoaded = true;
  }

  async loadImageAsDataUrl(url) {
    const resp = await fetch(url);
    const blob = await resp.blob();

    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(reader.result);
      reader.onerror = reject;
      reader.readAsDataURL(blob);
    });
  }

  stripHtmlToText(html) {
    if (!html) return '';

    let s = String(html)
      .replace(/<br\s*\/?\s*>/gi, '\n')
      .replace(/<\/p>/gi, '\n')
      .replace(/<\/div>/gi, '\n')
      .replace(/<\/li>/gi, '\n');

    s = s.replace(/<[^>]+>/g, '');

    const textarea = document.createElement('textarea');
    textarea.innerHTML = s;
    s = textarea.value;

    s = s.replace(/\u00A0/g, ' ');
    s = s.replace(/[ \t]+\n/g, '\n');
    s = s.replace(/\n{3,}/g, '\n\n');
    return s.trim();
  }

  formatDateDDMMYYYY(date) {
    const d = date instanceof Date ? date : new Date(date);
    const dd = String(d.getDate()).padStart(2, '0');
    const mm = String(d.getMonth() + 1).padStart(2, '0');
    const yyyy = d.getFullYear();
    return `${dd}.${mm}.${yyyy}`;
  }

  fileName() {
    const today = new Date();
    const yyyy = today.getFullYear();
    const mm = String(today.getMonth() + 1).padStart(2, '0');
    const dd = String(today.getDate()).padStart(2, '0');
    const dateStr = `${yyyy}${mm}${dd}`;
    const recordId = this.recordId || 'record';
    return `ExecutiveReport__${recordId}_${dateStr}.pdf`;
  }

  buildAttachmentLabel(att, idx) {
    const fallback = `File ${idx + 1}`;
    const name = String(att?.fileName || '').trim();
    if (!name) return fallback;

    const maxLen = 16;
    return name.length > maxLen ? `${name.slice(0, maxLen - 3)}...` : name;
  }

  resolveStatusColorByValue(status) {
    if (!status) return [0, 0, 0];
    const s = String(status).toLowerCase();

    if (s.includes('done')) return [128, 128, 128];       // #808080
    if (s.includes('in progress')) return [255, 140, 0];  // #FF8C00
    if (s.includes('related')) return [50, 205, 50];      // #32CD32
    if (s.includes('pending')) return [255, 0, 0];        // #FF0000

    return [0, 0, 0];
  }

  drawHeader(doc, ctx) {
    const { marginLeft, marginTop, pageWidth, headerHeight, logoDataUrl, reportDateStr } = ctx;

    doc.setDrawColor(22, 50, 92); // #16325c
    doc.setLineWidth(0.3);
    doc.line(marginLeft, marginTop + headerHeight, pageWidth - marginLeft, marginTop + headerHeight);

    if (logoDataUrl) {
      doc.addImage(logoDataUrl, 'PNG', marginLeft, marginTop + 2, 40, 16);
    }

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(18);
    doc.setTextColor(22, 50, 92);
    doc.text('Dashboard: Tasks, Ref.', pageWidth - marginLeft, marginTop + 10, { align: 'right' });

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(11);
    doc.setTextColor(112, 110, 107);
    doc.text(reportDateStr, pageWidth - marginLeft, marginTop + 16, { align: 'right' });
  }

  drawLegend(doc, ctx) {
    const { marginLeft, legendTop } = ctx;

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(10);
    doc.setTextColor(62, 62, 60);
    doc.text('Legend:', marginLeft, legendTop);

    const items = [
      { label: 'Done', rgb: [128, 128, 128] },
      { label: 'In Progress', rgb: [255, 140, 0] },
      { label: 'Related Task', rgb: [50, 205, 50] },
      { label: 'Pending / Requires ExCom Approval', rgb: [255, 0, 0] }
    ];

    let x = marginLeft + 18;
    const yBox = legendTop - 4;

    for (const it of items) {
      doc.setFillColor(...it.rgb);
      doc.roundedRect(x, yBox, 8, 4, 1, 1, 'F');

      doc.setFont('helvetica', 'normal');
      doc.setTextColor(62, 62, 60);
      doc.text(it.label, x + 10, legendTop);

      x += Math.min(10 + doc.getTextWidth(it.label) + 18, 110);
    }
  }

  drawFooter(doc, ctx) {
    const { marginLeft, pageWidth, pageHeight, marginBottom } = ctx;

    const pageCount = doc.getNumberOfPages();
    const pageNumber = doc.internal.getCurrentPageInfo().pageNumber;

    const footerY = pageHeight - marginBottom + 8;

    doc.setDrawColor(160, 160, 160);
    doc.setLineWidth(0.3);
    doc.line(marginLeft, footerY - 6, pageWidth - marginLeft, footerY - 6);

    doc.setFont('helvetica', 'normal');
    doc.setFontSize(9);
    doc.setTextColor(112, 110, 107);
    doc.text(`${pageNumber} | Page`, marginLeft, footerY);

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(9);
    doc.setTextColor(112, 110, 107);
    doc.text('DEVELOPMENT DEPARTMENT', marginLeft + 35, footerY);

  }

  measureRowPages(jsPDFCtor, head, body, tableTopY, margins, tableWidth, styles, headStyles, columnStyles, ctx) {
    const measureDoc = new jsPDFCtor({ orientation: 'landscape', unit: 'mm', format: 'a4' });

    const rowPageMap = {};

    this.drawHeader(measureDoc, ctx);
    this.drawLegend(measureDoc, ctx);
    this.drawFooter(measureDoc, ctx);

    measureDoc.autoTable({
      head,
      body,
      startY: tableTopY,
      margin: { left: margins.left, right: margins.right, top: tableTopY, bottom: margins.bottom },
      tableWidth,
      styles,
      headStyles,
      columnStyles,
      showHead: 'everyPage',

      didDrawCell: (data) => {
        if (data.section === 'body' && data.column.index === 0) {
          rowPageMap[data.row.index] = data.pageNumber;
        }
      },

      didDrawPage: () => {
        this.drawHeader(measureDoc, ctx);
        this.drawLegend(measureDoc, ctx);
        this.drawFooter(measureDoc, ctx);
      }
    });

    return rowPageMap;
  }

  computeProjectSpansPerPage(body, rowPageMap, projectColIndex = 1) {
    const spanMap = new Array(body.length).fill(1);

    let i = 0;
    while (i < body.length) {
      const page = rowPageMap[i];

      let j = i + 1;
      while (j < body.length && rowPageMap[j] === page) {
        j++;
      }

      const span = j - i;
      spanMap[i] = span;

      for (let k = i + 1; k < j; k++) {
        spanMap[k] = 0;
      }

      i = j;
    }

    return spanMap;
  }

  handleCancel() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  /* alterar cor do projeto name */
  /* getProjectColor(projectName) {
  if (!projectName) return [230, 230, 230];

  let hash = 0;
  for (let i = 0; i < projectName.length; i++) {
    hash = projectName.charCodeAt(i) + ((hash << 5) - hash);
  }

  const hue = Math.abs(hash) % 360;

  // HSL → RGB (pdf trabalha melhor com RGB)
  return this.hslToRgb(hue / 360, 0.4, 0.85); // fundo claro
}
*/

  /* alterar cor do projeto name */
  /* getProjectColor(projectName) {
  if (!projectName) return [230, 230, 230];

  let hash = 0;
  for (let i = 0; i < projectName.length; i++) {
    hash = projectName.charCodeAt(i) + ((hash << 5) - hash);
  }

  const hue = Math.abs(hash) % 360;

  // HSL → RGB (pdf trabalha melhor com RGB)
  return this.hslToRgb(hue / 360, 0.4, 0.85); // fundo claro
}
*/

  getProjectColor(projectName) {
    if (!projectName) return [200, 200, 200];

    const palette = [
      [85, 110, 55],
      [95, 125, 70],
      [75, 100, 50],
      [70, 95, 115],
      [60, 85, 105],
      [90, 115, 90]
    ];

    let hash = 0;
    for (let i = 0; i < projectName.length; i++) {
      hash = projectName.charCodeAt(i) + ((hash << 5) - hash);
    }

    return palette[Math.abs(hash) % palette.length];
  }

  hslToRgb(h, s, l) {
    let r, g, b;

    if (s === 0) {
      r = g = b = l;
    } else {
      const hue2rgb = (p, q, t) => {
        if (t < 0) t += 1;
        if (t > 1) t -= 1;
        if (t < 1 / 6) return p + (q - p) * 6 * t;
        if (t < 1 / 2) return q;
        if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
        return p;
      };

      const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
      const p = 2 * l - q;

      r = hue2rgb(p, q, h + 1 / 3);
      g = hue2rgb(p, q, h);
      b = hue2rgb(p, q, h - 1 / 3);
    }

    return [
      Math.round(r * 255),
      Math.round(g * 255),
      Math.round(b * 255)
    ];
  }

  async handleGenerate() {
    this.isLoading = true;

    try {
      await this.loadLibsIfNeeded();

      const jsPDF = window.jspdf?.jsPDF;
      if (!jsPDF) throw new Error('jsPDF not found (window.jspdf.jsPDF)');

      const rows = await getAssignments({ executiveReportId: this.recordId });

      const logoDataUrl = await this.loadImageAsDataUrl(LOGO);

      const doc = new jsPDF({ orientation: 'landscape', unit: 'mm', format: 'a4' });

      const pageWidth = doc.internal.pageSize.getWidth();
      const pageHeight = doc.internal.pageSize.getHeight();

      const marginLeft = 10;
      const marginRight = 10;
      const marginTop = 10;
      const marginBottom = 20;

      const headerHeight = 22;
      const reportDateStr = this.formatDateDDMMYYYY(new Date());

      const ctx = {
        pageWidth,
        pageHeight,
        marginLeft,
        marginRight,
        marginTop,
        marginBottom,
        headerHeight,
        legendTop: marginTop + headerHeight + 8,
        logoDataUrl,
        reportDateStr
      };

      const head = [[
        'Item',
        'Project',
        'Assignment',
        'Next Action',
        'Action By',
        'Target Date',
        'Status',
        'Attachments'
      ]];

      const projectGroups = [];
      let currentProject = null;
      let currentGroup = null;

      (rows || []).forEach((wrapper, idx) => {
        // Handle both old format (direct Project_Assignment__c) and new format (wrapper with assignment + attachments)
        const a = wrapper.assignment ? wrapper.assignment : wrapper;
        const attachments = wrapper.attachments ? wrapper.attachments : [];
        
        const projectName = a.Project__r?.Name || a.Name || '';

        if (projectName !== currentProject) {
          currentProject = projectName;
          currentGroup = {
            projectName: projectName,
            items: [],
            itemStartIndex: idx + 1
          };
          projectGroups.push(currentGroup);
        }

        currentGroup.items.push({
          itemNumber: currentGroup.items.length + 1,
          projectName: projectName,
          assignmentDescription: this.stripHtmlToText(a.Assignment_Description__c),
          nextAction: this.stripHtmlToText(a.Next_Action_Decision_Required__c),
          actionBy: a.Action_By2__c,
          targetStatus: a.Target_Status__c ?? '',
          priorityNotes: this.stripHtmlToText(a.Priority_Notes__c),
          attachments: attachments || []
        });
      });

      const tableWidth = pageWidth - marginLeft - marginRight;

      // Adjusted column weight distribution including new Attachments column (index 7).
      const base = [12, 25, 55, 35, 15, 15, 20, 18];
      const sum = base.reduce((acc, v) => acc + v, 0);
      const w = base.map(v => (v / sum) * tableWidth);

      const tableTopY = ctx.legendTop + 6;

      const styles = {
        font: 'helvetica',
        fontSize: 8,
        cellPadding: 3,
        valign: 'top',
        lineColor: [0, 0, 0],
        lineWidth: 0.2,
        textColor: [62, 62, 60],
        overflow: 'linebreak'
      };

      const headStyles = {
        /* fillColor: [22, 50, 92],*/
        fillColor: [220, 220, 220],
        textColor: [255, 255, 255],
        fontStyle: 'bold',
        lineColor: [0, 0, 0],
        lineWidth: 0.2
      };

      const columnStyles = {
        0: { cellWidth: w[0], halign: 'center', fontStyle: 'bold' },
        1: { cellWidth: w[1], halign: 'center', valign: 'middle', fontStyle: 'bold', lineWidth: 0 },
        2: { cellWidth: w[2] },
        3: { cellWidth: w[3] },
        4: { cellWidth: w[4] },
        5: { cellWidth: w[5], halign: 'center' },
        6: { cellWidth: w[6] },
        7: { cellWidth: w[7] }
      };

      let currentY = tableTopY;
      let isFirstPage = true;
      const attachmentLinksByPage = {}; // Store links by page number

      for (const group of projectGroups) {
        if (!isFirstPage) {
          doc.addPage();
          this.drawHeader(doc, ctx);
          this.drawLegend(doc, ctx);
          this.drawFooter(doc, ctx);
          currentY = tableTopY;
        }
        isFirstPage = false;

        // Build body for this project (project column styled per row)
        /* const body = group.items.map((item) => ([
          item.itemNumber,
          item.projectName,
          item.assignmentDescription,
          item.nextAction,
          item.actionBy,
          item.targetStatus,
          item.priorityNotes
        ])); */


        /* const body = group.items.map((item, index) => ([
          item.itemNumber,
          index === 0 ? item.projectName : '', // ← só a primeira linha
          item.assignmentDescription,
          item.nextAction,
          item.actionBy,
          item.targetStatus,
          item.priorityNotes
        ])); */

        
        // Build a raw body with the project name on every row so we can detect
        // where page breaks occur, then create a final body that shows the
        // project name on the first row of the group and at the start of each page.
        // Also store attachments metadata for creating clickable links later
        const attachmentsByRowIndex = {};
        
        const rawBody = group.items.map((item, itemIdx) => {
          // Format attachments as short link text
          const attachmentsList = item.attachments && item.attachments.length > 0
            ? item.attachments.map((att, idx) => this.buildAttachmentLabel(att, idx)).join('\n')
            : '';
          
          // Store attachments metadata by item index for links
          if (item.attachments && item.attachments.length > 0) {
            attachmentsByRowIndex[itemIdx] = item.attachments;
          }
          
          return [
            item.itemNumber,
            item.projectName,
            item.assignmentDescription,
            item.nextAction,
            item.actionBy,
            item.targetStatus,
            item.priorityNotes,
            attachmentsList
          ];
        });

        // Measure pages using a temporary jsPDF so measurement matches final render
        const tempDoc = new jsPDF({ orientation: 'landscape', unit: 'mm', format: 'a4' });
        const rowPageMap = {};

        // draw header/legend/footer on temp doc to match spacing
        this.drawHeader(tempDoc, ctx);
        this.drawLegend(tempDoc, ctx);
        this.drawFooter(tempDoc, ctx);

        tempDoc.autoTable({
          head,
          body: rawBody,
          startY: tableTopY,
          margin: { left: marginLeft, right: marginRight, top: tableTopY, bottom: marginBottom },
          tableWidth,
          styles,
          headStyles,
          columnStyles,
          showHead: 'everyPage',
          didDrawCell: (data) => {
            if (data.section === 'body' && data.column.index === 0) {
              rowPageMap[data.row.index] = data.pageNumber;
            }
          },
          didDrawPage: () => {
            this.drawHeader(tempDoc, ctx);
            this.drawLegend(tempDoc, ctx);
            this.drawFooter(tempDoc, ctx);
          }
        });

        // Build final body: show projectName on first row and on rows that start a new page
        const body = rawBody.map((r, idx) => {
          const showProject = (idx === 0) || (rowPageMap[idx] && rowPageMap[idx - 1] && rowPageMap[idx] !== rowPageMap[idx - 1]);
          return [r[0], showProject ? r[1] : '', r[2], r[3], r[4], r[5], r[6], r[7]];
        });


        /* const body = group.items.map((item, index) => {
        const row = [
             item.itemNumber,
             null, // Project Name (vamos tratar abaixo)
             item.assignmentDescription,
             item.nextAction,
             item.actionBy,
             item.targetStatus,
             item.priorityNotes
         ];

        // PRIMEIRA LINHA DO PROJETO
        if (index === 0) {
            row[1] = {
            content: item.projectName,
            rowSpan: group.items.length
        };
        } else {
            // DEMAIS LINHAS: célula "vazia"
            row[1] = '';
        }
        return row;
      }); */


        const statusMap = {};
        body.forEach((row, idx) => {
          statusMap[idx] = String(row[6] ?? '').trim();
        });

        doc.autoTable({
          head,
          body,
          startY: currentY,
          margin: { left: marginLeft, right: marginRight, top: currentY, bottom: marginBottom },
          tableWidth,
          showHead: 'everyPage',
          styles,
          headStyles,
          tableLineColor: [0, 0, 0],
          tableLineWidth: 0.6,
          columnStyles,

          didParseCell: (data) => {


            // FORÇA TEXTO PRETO NO HEADER
            if (data.section === 'head') {
              data.cell.styles.textColor = [0, 0, 0];   // PRETO
              data.cell.styles.fontStyle = 'bold';
            }

            if (data.section === 'body' && data.column.index === 1) {
              const projectName = group.projectName;
              const bgColor = this.getProjectColor(projectName);
              data.cell.styles.fillColor = bgColor;
              data.cell.styles.textColor = [0, 0, 0];
              data.cell.styles.fontStyle = 'bold';
              data.cell.styles.halign = 'center';
              data.cell.styles.valign = 'middle';
              data.cell.styles.lineWidth = 0;
            }

            if (data.section === 'body' && data.column.index === 6) {
              const rowIndex = data.row.index;
              let statusText = statusMap[rowIndex];

              if (!statusText && data.row.raw && data.row.raw.length > 5) {
                statusText = String(data.row.raw[6] ?? '').trim();
              }

              if (!statusText && body && body[rowIndex] && body[rowIndex].length > 5) {
                statusText = String(body[rowIndex][6] ?? '').trim();
              }

              statusText = statusText || '';

              if (statusText) {
                const rgb = this.resolveStatusColorByValue(statusText);
                data.cell.styles.textColor = rgb;

                if (statusText.toLowerCase().includes('pending')) {
                  data.cell.styles.fontStyle = 'bold';
                }
              } else {
                data.cell.styles.textColor = [0, 0, 0];
              }
            }

            // Style attachments column with blue color
            if (data.section === 'body' && data.column.index === 7) {
              data.cell.styles.textColor = [0, 0, 255];  // Blue color
              data.cell.styles.fontStyle = 'bold';
              data.cell.styles.halign = 'left';
              data.cell.styles.valign = 'top';
            }

            // REPLICAR COR DO PRIORITY / NOTES NAS OUTRAS COLUNAS
            if (
              data.section === 'body' &&
              [2, 3, 4, 5, 6].includes(data.column.index)
            ) {
              const rowIndex = data.row.index;
              const priorityText = String(data.row.raw?.[6] || '').trim();

              if (priorityText) {
                const rgb = this.resolveStatusColorByValue(priorityText);
                data.cell.styles.textColor = rgb;

                if (priorityText.toLowerCase().includes('pending')) {
                  data.cell.styles.fontStyle = 'bold';
                }
              }
            }
          },

          didDrawCell: (data) => {
            // Capture attachment cell positions and create download links
            if (data.section === 'body' && data.column.index === 7) {
              const rowIndex = data.row.index;
              if (attachmentsByRowIndex[rowIndex]) {
                const attachments = attachmentsByRowIndex[rowIndex];
                const pageNum = doc.internal.getNumberOfPages();
                
                // Store link data for this page
                if (!attachmentLinksByPage[pageNum]) {
                  attachmentLinksByPage[pageNum] = [];
                }
                
                const paddingTop = typeof data.cell.padding === 'function'
                  ? data.cell.padding('top')
                  : 1;
                let yOffset = paddingTop;
                attachments.forEach((att, idx) => {
                  if (!att.contentDocumentId) return;

                  const fileUrl = `${window.location.origin}/sfc/servlet.shepherd/document/download/${att.contentDocumentId}`;

                  const label = this.buildAttachmentLabel(att, idx);
                  const maxLinkWidth = Math.max(data.cell.width - 2, 2);
                  const textWidth = Math.min(doc.getTextWidth(label) + 1, maxLinkWidth);
                  const fontSizePt = data.cell.styles?.fontSize || styles.fontSize || 8;
                  const lineHeight = Math.max(fontSizePt * 0.3528, 2.5);
                  
                  // Store link to be added after rendering
                  attachmentLinksByPage[pageNum].push({
                    x: data.cell.x + 1,
                    y: data.cell.y + yOffset,
                    width: textWidth,
                    height: lineHeight,
                    url: fileUrl,
                    text: label
                  });

                  yOffset += lineHeight;
                });
              }
            }
          },

          didDrawPage: () => {
            this.drawHeader(doc, ctx);
            this.drawLegend(doc, ctx);
            this.drawFooter(doc, ctx);
          }
        });

        currentY = doc.lastAutoTable?.finalY ?? currentY;
      }

      // Add all the attachment download links that were captured during rendering
      Object.keys(attachmentLinksByPage).forEach((pageNum) => {
        const pageNumber = parseInt(pageNum);
        doc.setPage(pageNumber);
        
        attachmentLinksByPage[pageNum].forEach((linkData) => {
          doc.link(linkData.x, linkData.y, linkData.width, linkData.height, {
            url: linkData.url
          });
        });
      });

      doc.save(this.fileName());

      const dataUri = doc.output('datauristring');
      const base64 = dataUri.split('base64,')[1];
      const fileName = `Executive Report Assignments - ${this.formatDateDDMMYYYY(new Date())}.pdf`;

      await savePdfFromLwc({
        reportId: this.recordId,
        base64Data: base64,
        fileName: fileName
      });

      setTimeout(() => {
        this.handleCancel();
      }, 500);
    } catch (e) {
      console.error(e);
      alert(e?.message || 'Error generating PDF');
    } finally {
      this.isLoading = false;
    }
  }
}
