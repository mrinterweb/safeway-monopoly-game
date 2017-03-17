#! /usr/bin/env ruby

require 'optparse'
require 'sqlite3'
require 'sequel'

DB = Sequel.connect('sqlite://safeway.db')

class Code < Sequel::Model
  def validate
    super
    errors.add(:code, "Invalid format") if (code =~ /^(8|9)[a-z][0-9]{2}[a-h]$/) != 0
  end

  def before_create
    super
    self.code = code.downcase
    raise "invlaid code" if code.length != 5
    self.pk = code.slice(0, 2) + code.slice(-1, 1)
  end
end

class Safeway

  attr_reader :db

  def initialize
    # @db = SQLite3::Database.new "safeway.db"
    @db = DB
    create_codes_table
  end

  def run
    puts "Ctrl+c to exit"
    loop do
      prompt
    end
  rescue SignalException
    puts "\nGoodbye"
    exit
  end

  def prompt
    puts "Enter your code:"
    code = gets.chomp
    return if code.empty?
    if code == 'show'
      codes = Code.order(:code).all
      groups = codes.group_by { |c| c.pk.slice(0, 2) }
      groups.each do |char, group|
        puts "#{char} ================"
        group.each do |c|
          puts "pk: #{c.pk}, code: #{c.code}"
        end
      end
    elsif code == 'deleteall'
      Code.where.delete
    else
      puts "Code recorded" if insert(code)
    end
  end

  private

  def insert(code)
    Code.create(code: code)
    true
  rescue Sequel::ValidationFailed => e
    puts e
    false
  rescue Sequel::UniqueConstraintViolation
    puts "Duplicate code: #{code}"
    false
  end

  # def exists?(code)
  #   Code.where(pk: code).count >= 1
  # end

  # def create_db
  #   db.execute <<~SQL
  #     CREATE TABLE IF NOT EXISTS codes
  #     pk varchar(2),
  #     code varchar(10)
  #   SQL
  # end
  def create_codes_table
    db.create_table? :codes do
      String :pk, primary_key: true
      String :code
    end
  end
end

Safeway.new.run
