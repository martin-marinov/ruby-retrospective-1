require 'bigdecimal'
require 'bigdecimal/util'

class Product
  attr_reader :name, :price, :promo

  def initialize(name, price, promo)
    @name, @price, @promo = name, price, promo
  end
end


class Coupon
  attr_reader :name, :discount_type, :discount

  def initialize(name, type)
    @name = name
    @discount_type  = type.first.first
    @discount = @discount_type == :percent ? type.first.last :
    type.first.last.to_d
  end
end


class Invoice
  def initialize(cart)
    @cart = cart
  end

  def to_s
    invoice = header
    invoice << body
    invoice << coupon_line if @cart.coupon
    invoice << footer
  end

  def header
    <<-eos.gsub(/^\s+/, "")
        +------------------------------------------------+----------+
        | Name                                       qty |    price |
        +------------------------------------------------+----------+
    eos
  end

  def body
    body_invoice = ""
    @cart.each do | product, count |
      digits = count.to_s.length
      price = sprintf("%9.2f", product.price*count)
      body_invoice << "| #{product.name.ljust(46-digits)}#{count} |#{price} |\n"
      body_invoice << promo_line(product, count) unless product.promo.nil?
    end
    body_invoice
  end
  
  def promo_line(product, count)
    discount = sprintf("-%.2f",
    @cart.discount(product.price, count, product.promo)).rjust(9)
    "#{promo_name_line(product.promo.first)}|#{discount} |\n"
  end

  def promo_name_line(promo)
    case promo.first
    when :get_one_free then "|   (buy #{promo.last - 1}, get 1 free)".ljust(49)
    when :package
      nr, value = promo.last.first
      "|   (get #{value}% off for every #{nr})".ljust(49)
    when :threshold
      nr, value = promo.last.first
      "|   (#{value}% off of every after the #{nr}#{number_suffix(nr)})".ljust(49)
    end
  end

  def footer
    total = sprintf("%9.2f", @cart.total)
    <<-eos.gsub(/^\s+/, "")
      +------------------------------------------------+----------+
      | TOTAL                                          |#{total} |
      +------------------------------------------------+----------+
    eos
  end

  def coupon_line
    @cart.total # calculate total, now price_without_coupon is not nil
    off = @cart.coupon.discount_type == :percent ? "#{@cart.coupon.discount}%" :
    sprintf("%.2f", @cart.coupon.discount)
    name = "| Coupon #{@cart.coupon.name} - #{off} off".ljust(48) + " |"
    line = name + sprintf("-%9.2f", @cart.price_without_coupon) + " |\n"
  end

  def number_suffix(number)
    case number
    when 1 then "st"
    when 2 then "nd"
    when 3 then "rd"
    else "th"
    end
  end
end


class Cart
  attr_reader :coupon, :price_without_coupon

  def initialize(inventory)
    @cart = Hash.new(0)
    @inventory = inventory
  end

  def add(name, count=1)
    unless @inventory.products.key?(name) and (1..99) === count
      raise RuntimeError.new("Invalid parameters passed.")
    end
    product = @inventory.products[name]
    @cart[product] += count
  end

  def total
    @total = BigDecimal('0')
    @cart.each do |product, count |
      @total += product.promo.nil? ? product.price*count :
      product.price*count - discount(product.price, count, product.promo)
    end
    if @coupon
      @price_without_coupon = coupon_discount
      @total -= @price_without_coupon
    end
    @total
  end

  def discount(price, count, promo)
    case promo.keys.first
    when :get_one_free then (count/promo.values.first)*price
    when :package
      key, value = promo.first.last.first
      value*1e-2*price*key*(count/key)
    when :threshold
      key, value = promo.first.last.first
      count > key ? ((count - key)*price*value*1e-2).to_d : '0'.to_d
    end
  end

  def invoice
    Invoice.new(self).to_s
  end

  def use(coupon_name)
    @coupon = @inventory.coupons[coupon_name]
  end

  def coupon_discount
    if @coupon.discount_type == :percent
      @total*@coupon.discount*1e-2
    else
      @total - @coupon.discount > '0'.to_d ? @coupon.discount : @total
    end
  end

  def each(&block)
    #Defines each iterator for object Cart
    @cart.each(&block)
  end
end


class Inventory
  attr_reader :products, :coupons

  def initialize
    @products = {}
    @coupons = {}
  end

  def register(name, price, promo=nil)
    if name.length > 40 or
      not (('0.01'.to_d..'999.99'.to_d) === price.to_d) or @products[name]
        raise RuntimeError.new("Invalid parameters passed.")
    else 
      @products[name] = Product.new(name, price.to_d, promo)
    end
  end

  def register_coupon(name, type)
    @coupons[name] = Coupon.new(name, type)
  end

  def new_cart
    Cart.new(self)
  end
end