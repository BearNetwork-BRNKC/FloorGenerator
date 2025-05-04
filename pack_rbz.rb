#!/usr/bin/env ruby

require 'zip'
require 'fileutils'

# Configuration
EXTENSION_NAME = 'FloorGenerator'
VERSION = '1.0.0' # 根據您的插件版本設置
OUTPUT_NAME = "#{EXTENSION_NAME}_v#{VERSION}.rbz"
PLUGIN_FILES = ['FloorGenerator.rb', 'delauney3.rb', 'VoronoiXYZ.rb', 'LICENSE', 'README.md', 'extension.json']
PLUGIN_FOLDERS = ['BTW_Textures', 'FG_Icons'] # 資源文件夾

# Create temp directory with a unique name to avoid conflicts
temp_dir = "#{EXTENSION_NAME}_temp_#{Time.now.to_i}"
begin
  FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  FileUtils.mkdir_p(temp_dir)

  # Copy files and folders to temp directory
  puts "Copying files to temporary directory: #{temp_dir}"
  PLUGIN_FILES.each do |file|
    if File.exist?(file)
      FileUtils.cp(file, temp_dir)
      puts "Copied: #{file}"
    else
      puts "Warning: File not found: #{file}"
    end
  end

  PLUGIN_FOLDERS.each do |folder|
    if Dir.exist?(folder)
      FileUtils.cp_r(folder, temp_dir)
      puts "Copied folder: #{folder}"
    else
      puts "Warning: Folder not found: #{folder}"
    end
  end

  # Create zip file
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
  # Clean up
  if Dir.exist?(temp_dir)
    puts "Cleaning up temporary directory: #{temp_dir}"
    FileUtils.rm_rf(temp_dir)
  end
end