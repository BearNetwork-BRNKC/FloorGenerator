# FloorGenerator_loader.rb
#
# Copyright (c) 2025 [BuildRoyal]
# Originally created by sdmitch (original author of FloorGenerator)
#
# This file registers the FloorGenerator plugin with SketchUp.
#

require 'sketchup'
require 'extensions'

module FloorGenerator
  unless file_loaded?(__FILE__)
    begin
      extension = SketchupExtension.new('FloorGenerator', 'FloorGenerator/FloorGenerator.rb')
      extension.description = '用於生成地板圖案（木地板，瓷磚等）的插件.支持SketchUp 2024 Ruby API / A plugin for generating floor patterns (wood floors, tiles, etc.) in SketchUp. Supports SketchUp 2024 Ruby API.'
      extension.version = '1.0.0'
      extension.creator = 'BuildRoyal ChenTing'
      extension.copyright = '版權（C）2025 BuildRoyal ChenTing，最初由sdmitch創建'
      Sketchup.register_extension(extension, true)
      puts "FloorGenerator v1.0.0 loaded successfully!"
      puts "Creator: BuildRoyal ChenTing"
      puts "Copyright: 版權（C）2025 BuildRoyal ChenTing，最初由sdmitch創建"
    rescue NameError => e
      puts "Error registering extension: #{e.message}"
      UI.messagebox("無法載入 FloorGenerator 插件：#{e.message}")
      raise
    end
    file_loaded(__FILE__)
  end
end