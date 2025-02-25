class ReportsController < ApplicationController

  class GreyFormat1 < Spreadsheet::Format
    def initialize(gb_color, font_color)
      super :pattern => 1, :pattern_fg_color => gb_color,:color => font_color, :text_wrap => 1, :weight => :bold, :size => 11, :align => :center, :border => :thin
    end
  end

  class GreyFormat2 < Spreadsheet::Format
    def initialize(gb_color, font_color)
      super :pattern => 1, :pattern_fg_color => gb_color,:color => font_color, :text_wrap => 1, :weight => :bold, :size => 12, :align => :center, :border => :thin
    end
  end


  def order_report
    @filters = {}
    @selectorder_details = nil

    if ! current_user.unitadmin? && ! current_user.superadmin? && current_user.branch?
      @at_units = Unit.where("unit_type=? or unit_type=? or id=?", "delivery", "postbuy", current_user.unit.id)
    else
      @at_units = Unit.all
    end
    unless request.get?
      @selectorder_details = OrderDetail.accessible_by(current_ability).joins(:order).joins(:order=>[:unit]).joins(:commodity).joins(:commodity=>[:supplier])
      
      if !params[:create_at_start].blank? && !params[:create_at_start][:create_at_start].blank?
        @selectorder_details = @selectorder_details.where("orders.created_at >= ?", to_date(params[:create_at_start][:create_at_start]))
        @filters["create_at_start"] = params[:create_at_start][:create_at_start]
      end

      if !params[:create_at_end].blank? && !params[:create_at_end][:create_at_end].blank? 
        @selectorder_details = @selectorder_details.where("orders.created_at <= ?", to_date(params[:create_at_end][:create_at_end])+1.minute)
        @filters["create_at_end"] = params[:create_at_end][:create_at_end]
      end

      if !params[:check_at_start].blank? && !params[:check_at_start][:check_at_start].blank?
        @selectorder_details = @selectorder_details.where("order_details.check_at >= ?", to_date(params[:check_at_start][:check_at_start]))
        @filters["check_at_start"] = params[:check_at_start][:check_at_start]
      end

      if !params[:check_at_end].blank? && !params[:check_at_end][:check_at_end].blank?
        @selectorder_details = @selectorder_details.where("order_details.check_at <= ?", to_date(params[:check_at_end][:check_at_end])+1.minute)
        @filters["check_at_end"] = params[:check_at_end][:check_at_end]
      end

      if !params[:recheck_at_start].blank? && !params[:recheck_at_start][:recheck_at_start].blank?
        @selectorder_details = @selectorder_details.where("order_details.recheck_at >= ?", to_date(params[:recheck_at_start][:recheck_at_start]))
        @filters["recheck_at_start"] = params[:recheck_at_start][:recheck_at_start]
      end

      if !params[:recheck_at_end].blank? && !params[:recheck_at_end][:recheck_at_end].blank?
        @selectorder_details = @selectorder_details.where("order_details.recheck_at <= ?", to_date(params[:recheck_at_end][:recheck_at_end])+1.minute)
        @filters["recheck_at_end"] = params[:recheck_at_end][:recheck_at_end]
      end

      if !params[:supplier].blank? && !(params[:supplier].eql?"全部")
        @selectorder_details = @selectorder_details.where("suppliers.id = ?", params[:supplier].to_i)
        @filters["supplier"] = Supplier.find(params[:supplier].to_i).name
        @filters["supplier_option"] = params[:supplier]
      else
        @filters["supplier"] = "全部"
        @filters["supplier_option"] = "全部"
      end

      if !params[:commodity_name].blank? && !params[:commodity_name][:commodity_name].blank?
        @selectorder_details = @selectorder_details.where("commodities.name like ?", "%#{params[:commodity_name][:commodity_name]}%")
        @filters["commodity_name"] = params[:commodity_name][:commodity_name]
      end

      @filters['status'] = params[:status]
      if params[:status].eql? "receiving_closed"
        @selectorder_details = @selectorder_details.where("order_details.status = ? or order_details.status = ?", OrderDetail::statuses[:receiving], OrderDetail::statuses[:closed])
      elsif params[:status].eql? "not_canceled"
        @selectorder_details = @selectorder_details.where("order_details.status != ?", OrderDetail::statuses[:canceled])
      elsif !params[:status].eql? "all"
        @selectorder_details = @selectorder_details.where("order_details.status = ?", params[:status])
      end

      if !params[:price_start].blank? && !params[:price_start][:price_start].blank?
        @selectorder_details = @selectorder_details.where("order_details.price >= ?", params[:price_start][:price_start].to_f)
        @filters["price_start"] = params[:price_start][:price_start]
      end

      if !params[:price_end].blank? && !params[:price_end][:price_end].blank?
        @selectorder_details = @selectorder_details.where("order_details.price <= ?", params[:price_end][:price_end].to_f)
        @filters["price_end"] = params[:price_end][:price_end]
      end

      if !params[:at_unit].blank? && !(params[:at_unit].eql?"全部")
        @selectorder_details = @selectorder_details.where("order_details.at_unit_id = ?", params[:at_unit].to_i)
        @filters["at_unit"] = Unit.find(params[:at_unit].to_i).name
        @filters["at_unit_option"] = params[:at_unit]
      else
        @filters["at_unit"] = "全部"
        @filters["at_unit_option"] = "全部"
      end

      if !params[:create_unit_name].blank? && !params[:create_unit_name][:create_unit_name].blank?
        @selectorder_details = @selectorder_details.where("units.name like ?", "%#{params[:create_unit_name][:create_unit_name]}%")
        @filters["create_unit_name"] = params[:create_unit_name][:create_unit_name]
      end

      if !params[:order_user_name].blank? && !params[:order_user_name][:order_user_name].blank?
        @selectorder_details = @selectorder_details.where("orders.name like ?", "%#{params[:order_user_name][:order_user_name]}%")
        @filters["order_user_name"] = params[:order_user_name][:order_user_name]
      end

      if !params[:phone].blank? && !params[:phone][:phone].blank?
        @selectorder_details = @selectorder_details.where("orders.phone = ? or orders.tel = ?", params[:phone][:phone], params[:phone][:phone])
        @filters["phone"] = params[:phone][:phone]
      end

      if !params[:branch_no].blank? && !params[:branch_no][:branch_no].blank?
        @selectorder_details = @selectorder_details.where("order_details.branch_no = ?", params[:branch_no][:branch_no])
        @filters["branch_no"] = params[:branch_no][:branch_no]
      end

      if !params[:branch_name].blank? && !params[:branch_name][:branch_name].blank?
        @selectorder_details = @selectorder_details.where("order_details.branch_name like ?", "%#{params[:branch_name][:branch_name]}%")
        @filters["branch_name"] = params[:branch_name][:branch_name]
      end

      if !params[:order_no_start].blank? && !params[:order_no_start][:order_no_start].blank?
        @selectorder_details = @selectorder_details.where("orders.no >= ?", params[:order_no_start][:order_no_start])
        @filters["order_no_start"] = params[:order_no_start][:order_no_start]
      end

      if !params[:order_no_end].blank? && !params[:order_no_end][:order_no_end].blank?
        @selectorder_details = @selectorder_details.where("orders.no <= ?", params[:order_no_end][:order_no_end])
        @filters["order_no_end"] = params[:order_no_end][:order_no_end]
      end

      if !params[:is_query].blank? and params[:is_query].eql?"true"
        render '/reports/order_report'
      else
        if @selectorder_details.blank?
          flash[:alert] = "无数据"
          redirect_to :action => 'order_report'
        else
          send_data(order_report_xls_content_for(@filters, @selectorder_details),:type => "text/excel;charset=utf-8; header=present",:filename => "订单管理报表_#{Time.now.strftime("%Y%m%d")}.xls")  
        end
      end
    end
  end

  def order_report_xls_content_for(filters, reports) 
    xls_report = StringIO.new  
    book = Spreadsheet::Workbook.new  
    sheet1 = book.create_worksheet :name => "订单管理报表"  

    title = Spreadsheet::Format.new :weight => :bold, :size => 18
    filter = Spreadsheet::Format.new :size => 12
    red = Spreadsheet::Format.new :color => :red, :size => 12
    bold = Spreadsheet::Format.new :weight => :bold, :size => 10, :border => :thin
    body = Spreadsheet::Format.new :size => 10, :border => :thin, :align => :center

      # 设置列宽
    1.upto(2) do |i|
      sheet1.column(i).width = 20
    end
    3.upto(4) do |i|
      sheet1.column(i).width = 25
    end
    sheet1.column(5).width = 50
    6.upto(9) do |i|
      sheet1.column(i).width = 15
    end
    sheet1.column(10).width = 20
    11.upto(16) do |i|
      sheet1.column(i).width = 16
    end
    17.upto(18) do |i|
      sheet1.column(i).width = 10
    end
    sheet1.column(19).width = 35
    sheet1.column(20).width = 25
    sheet1.column(21).width = 15
    sheet1.column(22).width = 35
    23.upto(24) do |i|
      sheet1.column(i).width = 15
    end
    sheet1.column(25).width = 16
    26.upto(27) do |i|
      sheet1.column(i).width = 15
    end
    sheet1.column(28).width = 20

    # 设置行高
    sheet1.row(0).height = 40
    1.upto(2) do |i|
      sheet1.row(i).height = 30
    end
    sheet1.row(3).height = 20
    sheet1.row(4).height = 25

    # 表头
    # sheet1.merge_cells(start_row, start_col, end_row, end_col)      
    sheet1.row(0).default_format = title 
    sheet1.merge_cells(0, 0, 0, 28)
    sheet1[0,0] = "           订单管理报表"

    sheet1.row(1).default_format = filter
    sheet1.merge_cells(1, 0, 1, 2)
    sheet1[1,0] = "  下单时间：#{filters['create_at_start']}至#{filters['create_at_end']}"
    sheet1[1,3] = "供应商：#{filters['supplier']}"
    sheet1[1,5] = "商品名称：#{filters['commodity_name']}"
    sheet1[1,6] = "子订单状态： #{OrderDetail::STATUS_NAME_REPORT[filters['status'].to_sym]}"
    sheet1[1,9] = "收货人手机号码：#{filters['phone']}"
    sheet1.row(1).set_format(9,red)
    sheet1[1,12] = "收货人：#{filters['order_user_name']}"
    sheet1.row(1).set_format(12,red)
    sheet1[1,15] = "创建单位：#{filters['create_unit_name']}"
    sheet1.row(1).set_format(15,red)
    sheet1[1,18] = "营业部代码：#{filters['branch_no']}"
    
    sheet1.row(2).default_format = filter

    if current_user.unitadmin? || current_user.superadmin?
      sheet1[2,0] = "  单位名称：#{current_user.rolename}"
    else
      sheet1[2,0] = "  单位名称：#{current_user.unit.name}"
    end

    sheet1[2,3] = "价格区间：#{filters['price_start']} - #{filters['price_end']}"
    sheet1[2,5] = "目前流转单位：#{filters['at_unit']}"
    sheet1[2,6] = "复核时间：#{filters['recheck_at_start']}至#{filters['recheck_at_end']}"
    sheet1[2,9] = "审核时间：#{filters['check_at_start']}至#{filters['check_at_end']}"

    sheet1[2,12] = "主订单编号起始：#{filters['order_no_start']}"
    sheet1[2,15] = "主订单编号结束：#{filters['order_no_end']}"
    sheet1[2,18] = "营业部名称：#{filters['branch_name']}"
    
    
    sheet1[3,0] = "子订单信息"
    sheet1.merge_cells(3, 0, 3, 19) 
    
    sheet1[3,20] = "主订单信息区"
    sheet1.merge_cells(3, 20, 3, 28)
    0.upto(28) do |i|
      sheet1.row(3).set_format(i, GreyFormat1.new(:grey, :black))
    end 
    
    sheet1.row(4).concat %w{序号 子订单编号 商品编码 DMS商品编码 供应商 商品名称 数量 销售单价 商家结算价 订单状态 目前流转单位 营业部代码 营业部名称 下单时间 审核时间 复核时间 结单时间 是否审核过 是否复核过 最后一次驳回理由 主订单编号 收货人 收货地址 收货人电话 收货人手机 创建时间 创建人 创建单位 备注}
    0.upto(28) do |i|
      sheet1.row(4).set_format(i, GreyFormat2.new(:grey, :black))
    end

    # 表格内容
    count_row = 5
    i=1
    reports.each do |x|
      sheet1[count_row,0] = i
      sheet1[count_row,1] = x.no
      sheet1[count_row,2] = x.commodity.cno
      sheet1[count_row,3] = x.commodity.dms_no
      sheet1[count_row,4] = x.commodity.supplier.name
      sheet1[count_row,5] = x.commodity.name
      sheet1[count_row,6] = x.amount
      sheet1[count_row,7] = x.price.blank? ? "" : x.price.to_s(:rounded, precision: 2)
      sheet1[count_row,8] = x.cost_price.blank? ? "" : x.cost_price.to_s(:rounded, precision: 2)
      sheet1[count_row,9] = x.status_name
      sheet1[count_row,10] = x.at_unit.try :name
      sheet1[count_row,11] = x.try :branch_no
      sheet1[count_row,12] = x.try :branch_name
      sheet1[count_row,13] = l x.created_at
      sheet1[count_row,14] = l x.check_at if !x.check_at.blank?
      sheet1[count_row,15] = l x.recheck_at if !x.recheck_at.blank?
      sheet1[count_row,16] = l x.closed_at if !x.closed_at.blank?
      sheet1[count_row,17] = x.has_checked? ? "是" : "否"
      sheet1[count_row,18] = x.has_rechecked? ? "是" : "否"
      sheet1[count_row,19] = x.why_decline.blank? ? "" : x.why_decline
      sheet1[count_row,20] = x.order.no
      sheet1[count_row,21] = x.order.name
      sheet1[count_row,22] = x.order.address
      sheet1[count_row,23] = x.order.tel
      sheet1[count_row,24] = x.order.phone
      sheet1[count_row,25] = l x.order.created_at
      sheet1[count_row,26] = x.order.user.try :name
      sheet1[count_row,27] = x.order.unit.try :name
      sheet1[count_row,28] = x.order.desc

      0.upto(28) do |x|
        sheet1.row(count_row).set_format(x, body)
      end 
      sheet1.row(count_row).height = 30

      count_row += 1
      i += 1
    end

    sheet1[count_row,0] = "合计"
    sheet1[count_row,1] = "订单总数：#{reports.count}"
    sheet1[count_row,6] = "商品总数：#{reports.sum(:amount)}"
    sheet1[count_row,7] = "销售总额：#{reports.sum(:price).to_s(:rounded, precision: 2)}"
    sheet1[count_row,8] = "结算总额：#{reports.sum(:cost_price).to_s(:rounded, precision: 2)}"
    0.upto(28) do |x|
      sheet1.row(count_row).set_format(x, bold)
    end
    sheet1.row(count_row).height = 25

    count_row += 1
    sheet1.row(count_row).default_format = filter
    sheet1.merge_cells(count_row, 0, 0, 28)

    if current_user.unitadmin? || current_user.superadmin?
      sheet1[count_row,0] = "打印机构：#{current_user.rolename}                     打印人：#{current_user.name}                打印时间：#{Time.now.strftime('%Y-%m-%d %H:%m:%S')}"
    else
      sheet1[count_row,0] = "打印机构：#{current_user.unit.name}                     打印人：#{current_user.name}                打印时间：#{Time.now.strftime('%Y-%m-%d %H:%m:%S')}"

    end
    sheet1.row(count_row).height = 30

    book.write xls_report  
    xls_report.string
  end

  def supplier_report
    authorize! "report", "SupplierReport"

    @filters = {}
    units = []
    counts = {}
    amounts = {}
    prices = {}
    cost_prices = {}
    @reports = nil

    unless request.get?
      selectorder_details = OrderDetail.accessible_by(current_ability).joins(:order).joins(:order=>[:unit]).joins(:commodity).joins(:commodity=>[:supplier]).where("order_details.status = ?", "closed")

      if !params[:close_at_start].blank? && !params[:close_at_start][:close_at_start].blank?
        selectorder_details = selectorder_details.where("order_details.closed_at >= ?", to_date(params[:close_at_start][:close_at_start]))
        @filters["close_at_start"] = params[:close_at_start][:close_at_start]
      end

      if !params[:close_at_end].blank? && !params[:close_at_end][:close_at_end].blank?
        selectorder_details = selectorder_details.where("order_details.closed_at <= ?", to_date(params[:close_at_end][:close_at_end])+1.minute)
        @filters["close_at_end"] = params[:close_at_end][:close_at_end]
      end

      if !params[:commodity_name].blank? && !params[:commodity_name][:commodity_name].blank?
        selectorder_details = selectorder_details.where("commodities.name like ?", "%#{params[:commodity_name][:commodity_name]}%")
        @filters["commodity_name"] = params[:commodity_name][:commodity_name]
      end

      # if !params[:price_start].blank? && !params[:price_start][:price_start].blank?
      #   selectorder_details = selectorder_details.where("order_details.price >= ?", params[:price_start][:price_start].to_f)
      #   filters["price_start"] = params[:price_start][:price_start]
      # end

      # if !params[:price_end].blank? && !params[:price_end][:price_end].blank?
      #   selectorder_details=selectorder_details.where("order_details.price <= ?", params[:price_end][:price_end].to_f)
      #   filters["price_end"] = params[:price_end][:price_end]
      # end

      if !params[:supplier].blank? && !(params[:supplier].eql?"全部")
        selectorder_details = selectorder_details.where("suppliers.id = ?", params[:supplier].to_i)
        @filters["supplier"] = Supplier.find(params[:supplier].to_i).name
        @filters["supplier_option"] = params[:supplier]
      else
        @filters["supplier"] = "全部"
        @filters["supplier_option"] = "全部"
      end

      # params[:checkbox].each do |x|
      #   if (!x[1].blank?) && (x[1].eql?"1") 
      #     units << x[0].to_i
      #   end
      # end    

      # if !units.blank?  
      #   selectorder_details = selectorder_details.where("orders.unit_id in (?)", units)
      #   filters["units"] = units.map{|u| Unit.find(u).name}.compact.join(",")
      # else
      #   filters["units"] = "全部"
      # end 

      @reports = selectorder_details.order("suppliers.sno, commodities.cno").group("suppliers.sno").group("commodities.cno").pluck("suppliers.sno, commodities.cno, sum(order_details.amount), sum(order_details.cost_price * order_details.amount)")
        
      if !params[:is_query].blank? and params[:is_query].eql?"true"
        render '/reports/supplier_report'
      else
        if selectorder_details.blank?
          flash[:alert] = "无数据"
          redirect_to :action => 'supplier_report'
        else
          # counts = selectorder_details.order("suppliers.sno, commodities.cno").group("suppliers.sno").group("commodities.cno").count
          # amounts = selectorder_details.order("suppliers.sno, commodities.cno").group("suppliers.sno").group("commodities.cno").sum("order_details.amount")
          # prices = selectorder_details.order("suppliers.sno, commodities.cno").group("suppliers.sno").group("commodities.cno").sum("order_details.price * order_details.amount")
          # cost_prices = selectorder_details.order("suppliers.sno, commodities.cno").group("suppliers.sno").group("commodities.cno").sum("order_details.cost_price * order_details.amount")

          #suppliers.sno, commodities.cno,销售数量, 销售金额(元), 销售成本(元)
          
          send_data(supplier_report_xls_content_for(@filters,@reports),:type => "text/excel;charset=utf-8; header=present",:filename => "供应商销售结算报表_#{Time.now.strftime("%Y%m%d")}.xls")  
        end
      end
    end
  end

  def supplier_report_xls_content_for(filters, reports) 
    xls_report = StringIO.new  
    book = Spreadsheet::Workbook.new  
    sheet1 = book.create_worksheet :name => "供应商销售结算报表"  
    
    title = Spreadsheet::Format.new :weight => :bold, :size => 18
    filter = Spreadsheet::Format.new :size => 12
    red_filter = Spreadsheet::Format.new :color => :red, :size => 12
    red_body = Spreadsheet::Format.new :color => :red, :size => 10, :weight => :bold, :align => :center, :border => :thin
    bold = Spreadsheet::Format.new :weight => :bold, :size => 10, :border => :thin
    body = Spreadsheet::Format.new :size => 10, :border => :thin, :align => :center

    # 设置列宽
    1.upto(3) do |i|
      sheet1.column(i).width = 25
    end
    sheet1.column(4).width = 50
    5.upto(7) do |i|
      sheet1.column(i).width = 25
    end
    
    # 设置行高
    sheet1.row(0).height = 40
    1.upto(2) do |i|
      sheet1.row(i).height = 30
    end
    sheet1.row(3).height = 25
    
    # 表头
    # sheet1.merge_cells(start_row, start_col, end_row, end_col)      
    sheet1.row(0).default_format = title 
    sheet1.merge_cells(0, 0, 0, 7)
    sheet1[0,0] = "            供应商销售结算报表"

    sheet1.row(1).default_format = filter
    sheet1.merge_cells(1, 0, 1, 3)
    sheet1[1,0] = "  结单时间：#{filters['close_at_start']}至#{filters['close_at_end']}"
    sheet1.row(1).set_format(0,red_filter)
    sheet1[1,4] = "商品名称：#{filters['commodity_name']}"
    sheet1.row(2).default_format = filter
    sheet1[2,0] = "供应商：#{filters['supplier']}"
    # sheet1[2,4] = "机构名称：#{filters['units']}"
    # sheet1.row(2).set_format(4,red_filter)
    # sheet1[2,5] = "销售价格区间：#{filters['price_start']} - #{filters['price_end']}"
    # sheet1.row(2).set_format(5,red_filter)
    
    sheet1.row(3).concat %w{序号 供应商名称 商品编码 DMS商品编码 商品名称 销售数量 商家结算价(元) 销售成本(元)}
    0.upto(7) do |i|
      sheet1.row(3).set_format(i, GreyFormat2.new(:grey, :black))
    end

    # 表格内容
    count_row = 4
    i = 0
    xj_amount = 0
    # xj_sell_price = 0
    xj_cost_price = 0
    # xj_detail_price = 0
    xj_detail_cost_price = 0
    # xj_income = 0
    hj_amount = 0
    # hj_sell_price = 0
    # hj_cost_price = 0
    # hj_detail_price = 0
    hj_detail_cost_price = 0
    # hj_income = 0
    
    start_row = 4

    supplier_reports(reports).each do |supplier_sno, rows|
      start_row = count_row
      
      # last_uid = row[0]
      xj_amount = 0
      # xj_sell_price = 0
      # xj_cost_price = 0
      # xj_detail_price = 0
      xj_detail_cost_price = 0
      # xj_income = 0
      rows.each do |row|
        commodity = Commodity.find_by(cno: row[1])
        
        sheet1[count_row,2] = row[1]
        sheet1[count_row,3] = commodity.dms_no
        sheet1[count_row,4] = commodity.name
        sheet1[count_row,5] = row[2]
        xj_amount += row[2]
        # sheet1[count_row,6] = commodity.sell_price
        # xj_sell_price += commodity.sell_price
        sheet1[count_row,6] = (row[3] / row[2]).to_s(:rounded, precision: 2)
        # xj_cost_price += row[1] / row[0]
        # sheet1[count_row,8] = prices[key]
        # xj_detail_price += prices[key]
        sheet1[count_row,7] =  row[3].to_s(:rounded, precision: 2)
        xj_detail_cost_price += row[3]
        # income = prices[key] - cost_prices[key]
        # sheet1[count_row,10] = income
        # xj_income += income

        0.upto(7) do |x|
          sheet1.row(count_row).set_format(x, body)
        end 
        sheet1.row(count_row).height = 30

        count_row += 1
      end

      #合并
      sheet1[start_row,0] = i += 1
      sheet1.merge_cells(start_row, 0, count_row, 0)
      sheet1[start_row,1] = Supplier.find_by(sno: supplier_sno).try :name
      sheet1.merge_cells(start_row, 1, count_row, 1)
      #小计
      sheet1[count_row,2] = "小计"
      sheet1[count_row,3] = "---"
      sheet1[count_row,4] = "---"
      sheet1[count_row,5] = xj_amount
      hj_amount += xj_amount
      # sheet1[count_row,6] = xj_sell_price
      # hj_sell_price += xj_sell_price
      sheet1[count_row,6] = "---"
      # hj_cost_price += xj_cost_price
      # sheet1[count_row,8] = xj_detail_price
      # hj_detail_price += xj_detail_price
      sheet1[count_row,7] = xj_detail_cost_price.to_s(:rounded, precision: 2) 
      hj_detail_cost_price += xj_detail_cost_price
      # sheet1[count_row,10] = xj_income
      # hj_income += xj_income

      0.upto(1) do |x|
        sheet1.row(count_row).set_format(x, body)
      end 

      2.upto(7) do |x|
        sheet1.row(count_row).set_format(x, red_body)
      end

      count_row += 1
    end
    # count_row += 1    

    sheet1[count_row,0] = "合计"
    sheet1.merge_cells(count_row, 0, count_row, 4)
    sheet1[count_row,5] = hj_amount
    # sheet1[count_row,6] = hj_sell_price
    sheet1[count_row,6] = "---"
    # sheet1[count_row,8] = hj_detail_price
    sheet1[count_row,7] =  hj_detail_cost_price.to_s(:rounded, precision: 2) 
    # sheet1[count_row,10] = hj_income

    0.upto(7) do |x|
      sheet1.row(count_row).set_format(x, red_body)
    end 

    count_row += 1

    sheet1.row(count_row).default_format = filter
    sheet1.merge_cells(count_row, 0, 0, 7)

    if current_user.unitadmin? || current_user.superadmin?
      sheet1[count_row,0] = "打印机构：#{current_user.rolename}                     打印人：#{current_user.name}                打印时间：#{Time.now.strftime('%Y-%m-%d %H:%m:%S')}"
    else
      sheet1[count_row,0] = "打印机构：#{current_user.unit.name}                     打印人：#{current_user.name}                打印时间：#{Time.now.strftime('%Y-%m-%d %H:%m:%S')}"

    end
    sheet1.row(count_row).height = 30

    book.write xls_report  
    xls_report.string
  end

  def commodity_report
    authorize! "report", "CommodityReport"

    @filters = {}
    @select_commodities = nil

    unless request.get?
      @select_commodities = Commodity.all.order(:supplier_id, :cno)

      if !params[:create_at_start].blank? && !params[:create_at_start][:create_at_start].blank?
        @select_commodities = @select_commodities.where("created_at >= ?", to_date(params[:create_at_start][:create_at_start]))
        @filters["create_at_start"] = params[:create_at_start][:create_at_start]
      end

      if !params[:create_at_end].blank? && !params[:create_at_end][:create_at_end].blank?
        @select_commodities = @select_commodities.where("created_at <= ?", to_date(params[:create_at_end][:create_at_end])+1.minute)
        @filters["create_at_end"] = params[:create_at_end][:create_at_end]
      end

      if !params[:supplier].blank? && !(params[:supplier].eql?"全部")
        @select_commodities = @select_commodities.where("supplier_id = ?", params[:supplier].to_i)
        @filters["supplier"] = Supplier.find(params[:supplier].to_i).name
        @filters["supplier_option"] = params[:supplier]
      else
        @filters["supplier"] = "全部"
        @filters["supplier_option"] = "全部"
      end

      if !params[:commodity_name].blank? && !params[:commodity_name][:commodity_name].blank?
        @select_commodities = @select_commodities.where("name like ?", "%#{params[:commodity_name][:commodity_name]}%")
        @filters["commodity_name"] = params[:commodity_name][:commodity_name]
      end

      if !params[:is_on_sell].blank? && !(params[:is_on_sell].eql?"全部")
        @select_commodities = @select_commodities.where("is_on_sell = ?", (params[:is_on_sell].eql?"true"))
        @filters["is_on_sell"] = Commodity::IS_ON_SELL[params[:is_on_sell].to_sym]
        @filters["is_on_sell_option"] = params[:is_on_sell]
      else
        @filters["is_on_sell"] = "全部"
        @filters["is_on_sell_option"] = "全部"
      end

      if !params[:is_query].blank? and params[:is_query].eql?"true"
        render '/reports/commodity_report'
      else
        if @select_commodities.blank?
          flash[:alert] = "无数据"
          redirect_to :action => 'commodity_report'
        else
          send_data(commodity_report_xls_content_for(@filters, @select_commodities),:type => "text/excel;charset=utf-8; header=present",:filename => "商品管理报表_#{Time.now.strftime("%Y%m%d")}.xls")  
        end
      end
    end
  end

  def commodity_report_xls_content_for(filters, reports) 
    xls_report = StringIO.new  
    book = Spreadsheet::Workbook.new  
    sheet1 = book.create_worksheet :name => "商品管理报表"  
    
    title = Spreadsheet::Format.new :weight => :bold, :size => 18
    filter = Spreadsheet::Format.new :size => 12
    red_filter = Spreadsheet::Format.new :color => :red, :size => 12
    red_body = Spreadsheet::Format.new :color => :red, :size => 10, :align => :center, :border => :thin
    bold = Spreadsheet::Format.new :weight => :bold, :size => 10, :border => :thin
    body = Spreadsheet::Format.new :size => 10, :border => :thin, :align => :center

    # 设置列宽
    1.upto(3) do |i|
      sheet1.column(i).width = 30
    end
    sheet1.column(4).width = 50
    5.upto(9) do |i|
      sheet1.column(i).width = 25
    end
    sheet1.column(10).width = 50
    
    # 设置行高
    sheet1.row(0).height = 40
    1.upto(2) do |i|
      sheet1.row(i).height = 30
    end
    sheet1.row(3).height = 25
    
    # 表头
    # sheet1.merge_cells(start_row, start_col, end_row, end_col)      
    sheet1.row(0).default_format = title 
    sheet1.merge_cells(0, 0, 0, 10)
    sheet1[0,0] = "            商品管理报表表"

    sheet1.row(1).default_format = filter
    sheet1.merge_cells(1, 0, 1, 2)
    sheet1[1,0] = "  创建时间：#{filters['create_at_start']}至#{filters['create_at_end']}"
    sheet1[1,3] = "供应商：#{filters['supplier']}"    
    sheet1[1,5] = "商品名称：#{filters['commodity_name']}"
    sheet1.row(1).set_format(5,red_filter)
    sheet1.row(2).default_format = filter
    if current_user.unitadmin? || current_user.superadmin?
      sheet1[2,0] = "  单位名称：#{current_user.rolename}"
    else
      sheet1[2,0] = "  单位名称：#{current_user.unit.name}"
    end
    sheet1[2,5] = "是否上架：#{filters['is_on_sell']}"
    
    sheet1.row(3).concat %w{序号 供应商 商品编码 DMS商品编码 商品名称 商家结算价 最低销售价 是否上架 上架时间 下架时间 商品详情}
    0.upto(10) do |i|
      sheet1.row(3).set_format(i, GreyFormat2.new(:grey, :black))
    end

    # 表格内容
    count_row = 4
    i=1

    reports.each do |x|
      sheet1[count_row,0] = i
      sheet1[count_row,1] = x.supplier.try :name
      sheet1[count_row,2] = x.cno
      sheet1[count_row,3] = x.dms_no
      sheet1[count_row,4] = x.name
      sheet1[count_row,5] = x.cost_price.to_s(:rounded, precision: 2)
      sheet1[count_row,6] = x.sell_price.to_s(:rounded, precision: 2)
      sheet1[count_row,7] = x.is_on_sell_name
      sheet1[count_row,8] = l x.created_at
      sheet1[count_row,9] = l x.updated_at if ! x.is_on_sell
      sheet1[count_row,10] = x.desc
      
      0.upto(10) do |x|
        sheet1.row(count_row).set_format(x, body)
      end 
      sheet1.row(count_row).set_format(7,red_body)
      sheet1.row(count_row).height = 30

      count_row += 1
      i += 1
    end

    sheet1[count_row,1] = "合计"
    sheet1[count_row,2] = "商品总数：#{reports.count}"
    0.upto(10) do |x|
      sheet1.row(count_row).set_format(x, bold)
    end
    sheet1.row(count_row).height = 25

    count_row += 1
    sheet1.row(count_row).default_format = filter
    sheet1.merge_cells(count_row, 0, 0, 10)

    if current_user.unitadmin? || current_user.superadmin?
      sheet1[count_row,0] = "打印机构：#{current_user.rolename}                     打印人：#{current_user.name}                打印时间：#{Time.now.strftime('%Y-%m-%d %H:%m:%S')}"
    else
      sheet1[count_row,0] = "打印机构：#{current_user.unit.name}                     打印人：#{current_user.name}                打印时间：#{Time.now.strftime('%Y-%m-%d %H:%m:%S')}"

    end
    sheet1.row(count_row).height = 30

    book.write xls_report  
    xls_report.string
  end

  def unit_report
    authorize! "report", "UnitReport"

    @filters = {}
    @units = []
    counts = {}
    amounts = {}
    prices = {}
    cost_prices = {}
    @reports = nil

    unless request.get?
      selectorder_details = OrderDetail.accessible_by(current_ability).joins(:order).joins(:order=>[:unit]).joins(:commodity).joins(:commodity=>[:supplier]).where("order_details.status = ?", "closed")

      if !params[:close_at_start].blank? && !params[:close_at_start][:close_at_start].blank?
        selectorder_details = selectorder_details.where("order_details.closed_at >= ?", to_date(params[:close_at_start][:close_at_start]))
        @filters["close_at_start"] = params[:close_at_start][:close_at_start]
      end

      if !params[:close_at_end].blank? && !params[:close_at_end][:close_at_end].blank?
        selectorder_details = selectorder_details.where("order_details.closed_at < ?", to_date(params[:close_at_end][:close_at_end])+1.minute)
        @filters["close_at_end"] = params[:close_at_end][:close_at_end]
      end

      if !params[:commodity_name].blank? && !params[:commodity_name][:commodity_name].blank?
        selectorder_details = selectorder_details.where("commodities.name like ?", "%#{params[:commodity_name][:commodity_name]}%")
        @filters["commodity_name"] = params[:commodity_name][:commodity_name]
      end

      if !params[:price_start].blank? && !params[:price_start][:price_start].blank?
        selectorder_details = selectorder_details.where("order_details.price >= ?", params[:price_start][:price_start].to_f)
        @filters["price_start"] = params[:price_start][:price_start]
      end

      if !params[:price_end].blank? && !params[:price_end][:price_end].blank?
        selectorder_details = selectorder_details.where("order_details.price <= ?", params[:price_end][:price_end].to_f)
        @filters["price_end"] = params[:price_end][:price_end]
      end

      if !params[:supplier].blank? && !(params[:supplier].eql?"全部")
        selectorder_details = selectorder_details.where("suppliers.id = ?", params[:supplier].to_i)
        @filters["supplier"] = Supplier.find(params[:supplier].to_i).name
        @filters["supplier_option"] = params[:supplier]
      else
        @filters["supplier"] = "全部"
        @filters["supplier_option"] = "全部"
      end

      if (current_user.unit.blank?) || (current_user.unit.eql? Unit::DELIVERY) || (current_user.unit.eql? Unit::POSTBUY)
        params[:checkbox].each do |x|
          if (!x[1].blank?) && (x[1].eql?"1") 
            @units << x[0].to_i
          end
        end    

        if !@units.blank?  
          selectorder_details = selectorder_details.where("orders.unit_id in (?)", @units)
          @filters["units"] = @units.map{|u| Unit.find(u).name}.compact.join(",")
        else
          @filters["units"] = "全部"
        end 
      else
        selectorder_details = selectorder_details.where("orders.unit_id = ?", current_user.unit.id)
        @filters["units"] = current_user.unit.name
      end

      @reports = selectorder_details.order("units.id, commodities.cno").group("units.id").group("commodities.cno").pluck("units.id, commodities.cno, sum(order_details.amount), sum(order_details.price * order_details.amount), sum(order_details.cost_price * order_details.amount)")

      if !params[:is_query].blank? and params[:is_query].eql?"true"
        render '/reports/unit_report'
      else
        if selectorder_details.blank?
          flash[:alert] = "无数据"
          redirect_to :action => 'unit_report'
        else
          # counts = selectorder_details.order("units.id, commodities.cno").group("units.id").group("commodities.cno").count
          # amounts = selectorder_details.order("units.id, commodities.cno").group("units.id").group("commodities.cno").sum("order_details.amount")
          # prices = selectorder_details.order("units.id, commodities.cno").group("units.id").group("commodities.cno").sum("order_details.price * order_details.amount")
          # cost_prices = selectorder_details.order("units.id, commodities.cno").group("units.id").group("commodities.cno").sum("order_details.cost_price * order_details.amount")

          #units.id, commodities.cno,销售数量, 销售金额(元), 销售成本(元)
          
          
          send_data(unit_report_xls_content_for(@filters,@reports),:type => "text/excel;charset=utf-8; header=present",:filename => "机构销售结算报表_#{Time.now.strftime("%Y%m%d")}.xls")  
        end
      end
    end
  end

  def unit_report_xls_content_for(filters, reports) 
    xls_report = StringIO.new  
    book = Spreadsheet::Workbook.new  
    sheet1 = book.create_worksheet :name => "机构销售结算报表"  
    
    title = Spreadsheet::Format.new :weight => :bold, :size => 18
    filter = Spreadsheet::Format.new :size => 12
    red_filter = Spreadsheet::Format.new :color => :red, :size => 12
    red_body = Spreadsheet::Format.new :color => :red, :size => 10, :weight => :bold, :align => :center, :border => :thin
    bold = Spreadsheet::Format.new :weight => :bold, :size => 10, :border => :thin
    body = Spreadsheet::Format.new :size => 10, :border => :thin, :align => :center

    # 设置列宽
    sheet1.column(1).width = 40
    2.upto(3) do |i|
      sheet1.column(i).width = 25
    end
    4.upto(5) do |i|
      sheet1.column(i).width = 50
    end
    6.upto(11) do |i|
      sheet1.column(i).width = 25
    end
    
    # 设置行高
    sheet1.row(0).height = 40
    1.upto(2) do |i|
      sheet1.row(i).height = 30
    end
    sheet1.row(3).height = 25
    
    # 表头
    # sheet1.merge_cells(start_row, start_col, end_row, end_col)      
    sheet1.row(0).default_format = title 
    sheet1.merge_cells(0, 0, 0, 11)
    sheet1[0,0] = "            机构销售结算报表"

    sheet1.row(1).default_format = filter     
    sheet1.merge_cells(1, 0, 1, 2)
    sheet1[1,0] = "  结单时间：#{filters['close_at_start']}至#{filters['close_at_end']}"
    sheet1.row(1).set_format(0,red_filter)
    sheet1[1,3] = "商品名称：#{filters['commodity_name']}"
    sheet1.row(2).default_format = filter
    sheet1[2,0] = "  机构名称：#{filters['units']}"    
    sheet1[2,3] = "供应商：#{filters['supplier']}"
    sheet1[2,5] = "销售价格区间：#{filters['price_start']} - #{filters['price_end']}"
    sheet1.row(2).set_format(5,red_filter)
    
    sheet1.row(3).concat %w{序号 机构名称 商品编码 DMS商品编码 供应商 商品名称 销售数量 平均执行销售价(元) 商家结算价(元) 销售金额(元) 销售成本(元) 销售收入(元)}
    0.upto(11) do |i|
      sheet1.row(3).set_format(i, GreyFormat2.new(:grey, :black))
    end

    # 表格内容
    count_row = 4
    i = 0
    xj_amount = 0
    # xj_sell_price = 0
    # xj_cost_price = 0
    xj_detail_price = 0
    xj_detail_cost_price = 0
    xj_income = 0
    hj_amount = 0
    hj_sell_price = 0
    hj_cost_price = 0
    hj_detail_price = 0
    hj_detail_cost_price = 0
    hj_income = 0
    
    # last_uid = reports.first[0]
    # start_row = 4

    
    unit_reports(reports).each do |unit_id, rows|
      start_row = count_row
      
      # last_uid = row[0]
      xj_amount = 0
      # xj_sell_price = 0
      # xj_cost_price = 0
      xj_detail_price = 0
      xj_detail_cost_price = 0
      xj_income = 0

      rows.each do |row|
        commodity = Commodity.find_by(cno: row[1])

        sheet1[count_row,2] = row[1]
        sheet1[count_row,3] = commodity.dms_no
        sheet1[count_row,4] = commodity.supplier.try :name
        sheet1[count_row,5] = commodity.name
        sheet1[count_row,6] = row[2]
        xj_amount += row[2]
        sheet1[count_row,7] = (row[3] / row[2]).to_s(:rounded, precision: 2)
        # xj_sell_price += row[3] / row[2]
        sheet1[count_row,8] = (row[4] / row[2]).to_s(:rounded, precision: 2)
        # xj_cost_price += row[4] / row[2]
        sheet1[count_row,9] =  row[3].to_s(:rounded, precision: 2)
        xj_detail_price += row[3]
        sheet1[count_row,10] =  row[4].to_s(:rounded, precision: 2)
        xj_detail_cost_price += row[4]
        income = row[3] - row[4]
        sheet1[count_row,11] = income.to_s(:rounded, precision: 2)
        xj_income += income

        0.upto(11) do |x|
          sheet1.row(count_row).set_format(x, body)
        end 
        sheet1.row(count_row).height = 30

        count_row += 1
      end


      #合并
      sheet1[start_row,0] = i += 1
      sheet1.merge_cells(start_row, 0, count_row, 0)
      sheet1[start_row,1] = Unit.find(unit_id).try :name
      sheet1.merge_cells(start_row, 1, count_row, 1)
      
      #小计
      sheet1[count_row,2] = "小计"
      sheet1[count_row,3] = "---"
      sheet1[count_row,4] = "---"
      sheet1[count_row,5] = "---"
      sheet1[count_row,6] = xj_amount
      hj_amount += xj_amount
      sheet1[count_row,7] = "---"
      sheet1[count_row,8] = "---"
      # sheet1[count_row,7] = xj_sell_price
      # hj_sell_price += xj_sell_price
      # sheet1[count_row,8] = xj_cost_price
      # hj_cost_price += xj_cost_price
      sheet1[count_row,9] =  xj_detail_price.to_s(:rounded, precision: 2)
      hj_detail_price += xj_detail_price
      sheet1[count_row,10] =  xj_detail_cost_price.to_s(:rounded, precision: 2)
      hj_detail_cost_price += xj_detail_cost_price
      sheet1[count_row,11] =  xj_income.to_s(:rounded, precision: 2)
      hj_income += xj_income

      0.upto(1) do |x|
        sheet1.row(count_row).set_format(x, body)
      end 

      2.upto(11) do |x|
        sheet1.row(count_row).set_format(x, red_body)
      end 
        
      count_row += 1
    end

    sheet1[count_row,0] = "合计"
    sheet1.merge_cells(count_row, 0, count_row, 5)
    sheet1[count_row,6] = hj_amount
    sheet1[count_row,7] = "---"
    sheet1[count_row,8] = "---"
    # sheet1[count_row,7] = hj_sell_price
    # sheet1[count_row,8] = hj_cost_price
    sheet1[count_row,9] = hj_detail_price.to_s(:rounded, precision: 2)
    sheet1[count_row,10] = hj_detail_cost_price.to_s(:rounded, precision: 2)
    sheet1[count_row,11] = hj_income.to_s(:rounded, precision: 2)

    0.upto(11) do |x|
      sheet1.row(count_row).set_format(x, red_body)
    end 

    count_row += 1
    sheet1.row(count_row).default_format = filter
    sheet1.merge_cells(count_row, 0, 0, 11)
    
    if current_user.unitadmin? || current_user.superadmin?
      sheet1[count_row,0] = "打印机构：#{current_user.rolename}                     打印人：#{current_user.name}                打印时间：#{Time.now.strftime('%Y-%m-%d %H:%m:%S')}"
    else
      sheet1[count_row,0] = "打印机构：#{current_user.unit.name}                     打印人：#{current_user.name}                打印时间：#{Time.now.strftime('%Y-%m-%d %H:%m:%S')}"

    end
    sheet1.row(count_row).height = 30

    book.write xls_report  
    xls_report.string
  end


  private
  def supplier_reports(reports)
    supplier_sno = reports[0][0]
    rows = []
    supplier_reports = {supplier_sno => rows}
    reports.each do |row|
      if !row[0].eql? supplier_sno
        supplier_sno = row[0]
        rows = []
        supplier_reports[supplier_sno] = rows
      end
      rows.append row
    end
    supplier_reports
  end

  def unit_reports(reports)
    unit_id = reports[0][0]
    rows = []
    unit_reports = {unit_id => rows}
    reports.each do |row|
      if !row[0].eql? unit_id
        unit_id = row[0]
        rows = []
        unit_reports[unit_id] = rows
      end
      rows.append row
    end
    unit_reports
  end

  def to_date(time)
    # date = Date.civil(time.split(/-|\//)[0].to_i,time.split(/-|\//)[1].to_i,time.split(/-|\//)[2].to_i)
    time.to_time
    # return date
  end
end