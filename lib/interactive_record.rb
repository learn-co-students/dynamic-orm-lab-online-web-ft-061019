require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

   def self.table_name
      self.to_s.downcase.pluralize
   end

   def self.column_names
      sql = <<-SQL
         PRAGMA table_info(\'#{table_name}\')
      SQL

      table_columns_raw = DB[:conn].execute(sql)
      
      #grab out of the hash the name of each table column
      column_names = table_columns_raw.map {|raw_info| raw_info["name"]}.compact
   end

   def initialize(attribs={})
      attribs.each do |attribute, value|
         self.send("#{attribute}=", value)
      end
   end

   def table_name_for_insert
      self.class.table_name
   end

   def col_names_for_insert
      self.class.column_names.delete_if {|column_name| column_name == "id"}.join(", ")
   end

   def values_for_insert
      self.class.column_names.delete_if {|column_name| column_name == "id"}.map {|column_name| "\'#{self.send(column_name)}\'"}.join(", ")
   end

   def save
      sql = <<-SQL
         INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert});
      SQL
      
      DB[:conn].execute(sql.strip)
      
      @id = DB[:conn].execute("SELECT last_insert_rowid() from #{table_name_for_insert}")[0][0]
   end
   
   def self.find_by_name(name)
      sql = <<-SQL
         SELECT * FROM #{self.table_name} WHERE name = ?;
      SQL
   
      DB[:conn].execute(sql.strip, name)
   end

   def self.find_by(attrib_hash)
      attrib_name = attrib_hash.keys.first.to_s
      attrib_value = attrib_hash.values.first.class == String ? "\'#{attrib_hash.values.first}\'" : attrib_hash.values.first

      sql = <<-SQL
         SELECT * FROM #{self.table_name} WHERE #{attrib_name} = #{attrib_value};
      SQL
      DB[:conn].execute(sql.strip)
   end
   

end