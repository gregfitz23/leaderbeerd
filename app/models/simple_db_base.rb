require "active_model"

class SimpleDbBase
  include ActiveModel::AttributeMethods
  
  class << self
    attr_accessor :table_name, :id_field, :attributes
    
    def table
      return @table if @table
    
      @db ||= AWS::SimpleDB.new(
        :access_key_id => Leaderbeerd::Config.aws_key,
        :secret_access_key => Leaderbeerd::Config.aws_secret
      )

      @table = @db.domains[table_name]          
      @table
    end
    
    def attributes
      @attributes ||= []
    end
    
    def attributes=(attrs)
      attrs.each do |a|
        attributes << a
        attr_accessor a
      end
      @attributes = attrs
    end
    
    def id_field
      @id_field ||= self.to_s.split("::")[-1].downcase + "_id"
    end
    
    def find(id)
      item_to_model(table.items[id])
    end

    def create(attributes)
      Leaderbeerd::Config.logger.debug "Creating #{self.table_name} with #{attributes.inspect}"

      puts id_field
      id = attributes[id_field]
      puts id
      item = self.table.items[id]
      item.attributes.add(attributes)

      item_to_model(item)
    end
    
    def all(options = {})
      items = []

      options[:order] ||= [id_field.to_sym, :asc]
      proxy = self.table
        .items
        .select(:all)
        .order(*options[:order])
        
      proxy = proxy.where(options[:where]) if options[:where]

      proxy.each {|i| items << item_to_model(i)}
        
      items        
    end
    

    private
    ##
    # Convert an SDB item to a model
    #
    def item_to_model(item)
      ret_attributes = {}
      ret_attributes[id_field] = item.name
      
      data_attributes = item.respond_to?(:data) ? item.data.attributes : item.attributes
      (attributes - [id_field.to_sym]).each do |a|
        attribute_name = a.to_s
        values = data_attributes[attribute_name]
        if values
          val = attribute_name.pluralize == attribute_name ? values : values.select {|v| !v.nil?}.first #if attribute looks like an array, return an array
          ret_attributes.merge!({a => val })
        end
      end
      
      self.new(ret_attributes)
    end
  end
  
  ## 
  # Initialize the model with the given attributes
  #
  def initialize(attrs = {})
    attrs.each_pair do |name, value|
      self.__send__("#{name}=", value) if self.class.attributes.include?(name) || name == self.class.id_field
    end
  end
  
  ##
  # Convert the 
  #
  def id
    self.send(self.class.id_field)
  end
  
  def save
    item = self.class.table.items[self.id]
    item.attributes.put(replace: attributes)
  end
  
  def delete
    self.class.table.items[self.id].delete
  end
  
  def attributes
    self.class.attributes.inject({}) do |hash, a|
      hash.merge({a => self.send(a)})
    end
  end
  
end