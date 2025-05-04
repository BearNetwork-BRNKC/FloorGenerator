#!/usr/bin/env ruby

require 'zip'
require 'fileutils'

# 配置
EXTENSION_NAME = 'FloorGenerator'
VERSION = '1.0.0'
OUTPUT_NAME = "#{EXTENSION_NAME}_v#{VERSION}.rbz"
PLUGIN_FILES = [
  'FloorGenerator/FloorGenerator.rb',
  'FloorGenerator/delauney3.rb',
  'FloorGenerator/VoronoiXYZ.rb',
  'FloorGenerator/LICENSE',
  'FloorGenerator/README.md'
]
PLUGIN_FOLDERS = [
  'FloorGenerator/BTW_Textures',
  'FloorGenerator/FG_Icons'
]
LOADER_FILE = 'FloorGenerator_loader.rb'
EXTENSION_JSON = 'extension.json'

# 創建具有唯一名稱的目錄以避免衝突
temp_dir = "#{EXTENSION_NAME}_temp_#{Time.now.to_i}"
begin
  FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  FileUtils.mkdir_p(temp_dir)

  # 創建 FloorGenerator 資料夾
  floor_generator_dir = File.join(temp_dir, 'FloorGenerator')
  FileUtils.mkdir_p(floor_generator_dir)

  # 將文件複製到臨時目錄的 FloorGenerator 資料夾中
  puts "Copying files to temporary directory: #{floor_generator_dir}"
  PLUGIN_FILES.each do |file|
    if File.exist?(file)
      FileUtils.cp(file, floor_generator_dir)
      puts "Copied: #{file}"
    else
      puts "Warning: File not found: #{file}"
    end
  end

  PLUGIN_FOLDERS.each do |folder|
    if Dir.exist?(folder)
      FileUtils.cp_r(folder, floor_generator_dir)
      puts "Copied folder: #{folder}"
    else
      puts "Warning: Folder not found: #{folder}"
    end
  end

  # 將 FloorGenerator_loader.rb 複製到臨時目錄的根目錄
  if File.exist?(LOADER_FILE)
    FileUtils.cp(LOADER_FILE, temp_dir)
    puts "Copied: #{LOADER_FILE}"
  else
    puts "Warning: File not found: #{LOADER_FILE}"
  end

  # 將 extension.json 複製到臨時目錄的根目錄
  if File.exist?(EXTENSION_JSON)
    FileUtils.cp(EXTENSION_JSON, temp_dir)
    puts "Copied: #{EXTENSION_JSON}"
  else
    puts "Warning: File not found: #{EXTENSION_JSON}"
  end

  # 創建 zip 文件
  if File.exist?(OUTPUT_NAME)
    puts "Removing existing file: #{OUTPUT_NAME}"
    FileUtils.rm(OUTPUT_NAME)
  end

  file_count = 0
  Zip::File.open(OUTPUT_NAME, create: true) do |zipfile|
    Dir["#{temp_dir}/**/**"].each do |file|
      next if File.directory?(file)
      zip_path = file.sub("#{temp_dir}/", '')
      zipfile.add(zip_path, file)
      puts "Added: #{zip_path}"
      file_count += 1
    end
  end

  puts "Created #{OUTPUT_NAME} with #{file_count} files"

ensure
  # 清理
  if Dir.exist?(temp_dir)
    puts "Cleaning up temporary directory: #{temp_dir}"
    FileUtils.rm_rf(temp_dir)
  end
end