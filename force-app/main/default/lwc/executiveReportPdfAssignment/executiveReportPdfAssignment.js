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
      .replace(/<br\s*\/?>/gi, '\n')
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

  async handleGenerate() {
    this.isLoading = true;

    try {
      await this.loadLibsIfNeeded();

      const jsPDF = window.jspdf?.jsPDF;
      if (!jsPDF) throw new Error('jsPDF not found (window.jspdf.jsPDF)');

      const rows = await getAssignments({ executiveReportId: this.recordId });

      console.log('rows sample', JSON.parse(JSON.stringify(rows?.[0])));
      console.log('project name sample', rows?.[0]?.Project__r?.Name);

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
        'Project / Name',
        'Assignment Description',
        'Next Action / Decision Required',
        'Action By',
        'Target / Status',
        'Priority / Notes'
      ]];

      const projectGroups = [];
      let currentProject = null;
      let currentGroup = null;

      (rows || []).forEach((a, idx) => {
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
          actionBy: a.Action_By__r?.Name ?? '',
          targetStatus: a.Target_Status__c ?? '',
          priorityNotes: this.stripHtmlToText(a.Priority_Notes__c)
        });
      });

      const tableWidth = pageWidth - marginLeft - marginRight;

      const base = [12, 38, 52, 70, 28, 28, 40];
      const sum = base.reduce((acc, v) => acc + v, 0);
      const w = base.map(v => (v / sum) * tableWidth);

      const tableTopY = ctx.legendTop + 6;

      const styles = {
        font: 'helvetica',
        fontSize: 9,
        cellPadding: 3,
        valign: 'top',
        lineColor: [0, 0, 0],
        lineWidth: 0.2,
        textColor: [62, 62, 60],
        overflow: 'linebreak'
      };

      const headStyles = {
        fillColor: [22, 50, 92],
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
        6: { cellWidth: w[6] }
      };

      let currentY = tableTopY;
      let isFirstPage = true;

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
        const body = group.items.map((item) => ([
          item.itemNumber,
          item.projectName,
          item.assignmentDescription,
          item.nextAction,
          item.actionBy,
          item.targetStatus,
          item.priorityNotes
        ]));

        const statusMap = {};
        body.forEach((row, idx) => {
          statusMap[idx] = String(row[5] ?? '').trim();
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
            if (data.section === 'body' && data.column.index === 1) {
              data.cell.styles.fillColor = [22, 50, 92];
              data.cell.styles.textColor = [255, 255, 255];
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
          },

          didDrawPage: () => {
            this.drawHeader(doc, ctx);
            this.drawLegend(doc, ctx);
            this.drawFooter(doc, ctx);
          }
        });

        currentY = doc.lastAutoTable?.finalY ?? currentY;
      }

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