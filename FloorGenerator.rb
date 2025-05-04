# FloorGenerator.rb
#
# Copyright (c) 2025 [BuildRoyal]
# Originally created by sdmitch (original author of FloorGenerator)
#
# This plugin is free software: you can redistribute it and/or modify
# it under the terms of the MIT License. See the LICENSE file for details.
#
# This is a maintained version of the original FloorGenerator plugin,
# updated and enhanced for compatibility with SketchUp 2024 and later.
#

require 'Sketchup'

unless $sdm_tools_menu
  $sdm_tools_menu = UI.menu("Plugins").add_submenu("SDM Tools")
  $sdm_Edge_tools = $sdm_tools_menu.add_submenu("Edge Tool")
  $sdm_Face_tools = $sdm_tools_menu.add_submenu("Face Tool")
  $sdm_CorG_tools = $sdm_tools_menu.add_submenu("CorG Tool")
  $sdm_Misc_tools = $sdm_tools_menu.add_submenu("Misc Tool")
end
unless file_loaded?(__FILE__)
  $sdm_Face_tools.add_item('FloorGenerator') { Sketchup.active_model.select_tool SDM::FloorGenerator.new }
  tb = UI::Toolbar.new("FlrGen")
  cmd = UI::Command.new("FlrGen") { Sketchup.active_model.select_tool SDM::FloorGenerator.new }
  cmd.small_icon = cmd.large_icon = File.join(File.dirname(__FILE__).gsub('\\','/'), "FG_Icons/Brick.jpg")
  cmd.tooltip = "Floor Generator"
  tb.add_item cmd
  tb.show unless tb.get_last_state == 0
  file_loaded(__FILE__)
end

module SDM
  class FloorGenerator
    @@dlg_FG_Main = @@opt = nil

    def initialize
      @mod = Sketchup.active_model
      @ent = @mod.active_entities
      @sel = @mod.selection
      @vue = @mod.active_view
      @ip = Sketchup::InputPoint.new
      @colors = Sketchup::Color.names
      @separator = begin; '1.0'.to_l; '.'; rescue; ','; end
      @icons = File.join(File.dirname(__FILE__).gsub('\\','/'), "FG_Icons/")
      RUBY_PLATFORM =~ /(darwin)/ ? @font = "Helvetica" : @font = "Arial"
      @current_units = Sketchup.active_model.options["UnitsOptions"]["LengthUnit"]
      @current_precision = Sketchup.active_model.options["UnitsOptions"]["LengthPrecision"]
      @@opt ||= "Tile"
      @@opt = Sketchup.read_default("FloorGenerator", "", @@opt)
      self.dialog
      self.source_of_textures if @app == "Rand_Tex"
    end

    def dialog
      if Sketchup.active_model.options["UnitsOptions"]["LengthUnit"] > 1
        Sketchup.active_model.options["UnitsOptions"]["LengthUnit"] = 2 # millimeters
        Sketchup.active_model.options["UnitsOptions"]["LengthPrecision"] = 1
        @defaults = ["Corner", "0", "Current", "No", "No", "50", "No", "No", "0", "No", "No", "30", "150", "50", "6", "6", "3", "No", "Yes", "0", "0", "3", "6", "1", "1", 'No', 'No'] if @@opt == "Brick" || @@opt == "Wedge"
        @defaults = ["Corner", "0", "Current", "No", "No", "0", "No", "No", "0", "No", "No", "30", "300", "300", "6", "3", "3", "No", "Yes", "0", "0", "3", "6", "1", "1", 'No', 'No'] if @@opt == "Tile" || @@opt == "HpScth4"
        @defaults = ["Corner", "0", "Current", "Yes", "Yes", "0", "No", "No", "0", "No", "No", "30", "2000", "100", "3", "3", "3", "No", "Yes", "0", "0", "3", "6", "1", "1", 'No', 'No'] if @@opt == "Wood"
        @defaults = ["Corner", "0", "Current", "No", "No", "0", "No", "No", "0", "No", "No", "30", "150", "50", "12", "6", "3", "Yes", "Yes", "0", "0", "3", "6", "1", "1", 'No', 'No'] if @@opt == "Tweed"
        @defaults = ["Corner", "0", "Current", "No", "No", "0", "No", "No", "0", "No", "No", "30", "200", "100", "12", "6", "3", "Yes", "Yes", "0", "0", "3", "6", "1", "1", 'No', 'No'] if @@opt == "Hbone" || @@opt == "BsktWv" || @@opt == "I_Block"
        @defaults = ["Center", "0", "Current", "No", "No", "0", "No", "No", "0", "No", "No", "30", "300", "300", "12", "6", "3", "Yes", "Yes", "0", "0", "3", "6", "1", "1", 'No', 'No'] if @@opt == "HpScth1" || @@opt == "HpScth2"
        @defaults = ["Corner", "0", "Current", "No", "No", "0", "No", "No", "0", "No", "No", "30", "600", "600", "6", "3", "3", "No", "Yes", "0", "0", "3", "6", "1", "1", 'No', 'No'] if @@opt == "HpScth3"
        @defaults = ["Center", "0", "Current", "No", "No", "0", "No", "No", "0", "No", "No", "30", "300", "0", "12", "6", "3", "No", "Yes", "0", "0", "3", "6", "1", "1", 'No', 'No'] if @@opt == "Hexgon" || @@opt == "Octgon" || @@opt == "IrPoly" || @@opt == "Diamonds"
      else
        Sketchup.active_model.options["UnitsOptions"]["LengthUnit"] = 0 # inches
        Sketchup.active_model.options["UnitsOptions"]["LengthPrecision"] = 3
        @defaults = ["Corner", "0", "Current", "No", "No", "50", "No", "No", "0", "No", "No", "30", "6.0", "2.0", "0.25", "0.25", "3", "No", "Yes", "0", "0", "0.125", "0.25", "1", "1", 'No', 'No'] if @@opt == "Brick" || @@opt == "Wedge"
        @defaults = ["Corner", "0", "Current", "No", "No", "0", "No", "No", "0", "No", "No", "30", "12.0", "12.0", "0.25", "0.125", "3", "No", "Yes", "0", "0", "0.125", "0.25", "1", "1", 'No', 'No'] if @@opt == "Tile" || @@opt == "HpScth4"
        @defaults = ["Corner", "0", "Current", "Yes", "Yes", "0", "No", "No", "0", "No", "No", "30", "60.0", "3.0", "0.125", "0.125", "3", "No", "Yes", "0", "0", "0.125", "0.25", "1", "1", 'No', 'No'] if @@opt == "Wood"
        @defaults = ["Corner", "0", "Current", "No", "No", "0", "No", "No", "0", "No", "No", "30", "6.0", "2.0", "0.5", "0.25", "3", "Yes", "Yes", "0", "0", "0.125", "0.25", "1", "1", 'No', 'No'] if @@opt == "Tweed"
        @defaults = ["Corner", "0", "Current", "No", "No", "0", "No", "No", "0", "No", "No", "30", "8.0", "4.0", "0.5", "0.25", "3", "Yes", "Yes", "0", "0", "0.125", "0.25", "1", "1", 'No', 'No'] if @@opt == "Hbone" || @@opt == "BsktWv" || @@opt == "I_Block"
        @defaults = ["Center", "0", "Current", "No", "No", "0", "No", "No", "0", "No", "No", "30", "12.0", "12.0", "0.5", "0.25", "3", "Yes", "Yes", "0", "0", "0.125", "0.25", "1", "1", 'No', 'No'] if @@opt == "HpScth1" || @@opt == "HpScth2" || @@opt == 'HpScth3'
        @defaults = ["Corner", "0", "Current", "No", "No", "0", "No", "No", "0", "No", "No", "30", "24.0", "24.0", "0.25", "0.125", "3", "No", "Yes", "0", "0", "0.125", "0.25", "1", "1", 'No', 'No'] if @@opt == "HpScth3"
        @defaults = ["Center", "0", "Current", "No", "No", "0", "No", "No", "0", "No", "No", "30", "12.0", "0.0", "0.5", "0.25", "3", "No", "Yes", "0", "0", "0.125", "0.25", "1", "1", 'No', 'No'] if @@opt == "Hexgon" || @@opt == "Octgon" || @@opt == "IrPoly" || @@opt == "Diamonds"
      end

      begin
        @spt, @rot, @app, @flw, @fww, r2r, @rtt, @rtr, txs, @rfr, @bev, twa, tbx, tby, gw, gd, bwb, @ate, @fwt, rds, rin, rix, bvs, ipd, rti, @cbf, @cig = Sketchup.read_default("FloorGenerator", @@opt, @defaults)
        @GX = tbx.to_l
        @GY = tby.to_l
        @GW = gw.to_l
        @HW = @GW / 2.0
        @GD = gd.to_l
        @bwb = bwb.to_i
        @rds = rds.to_i
        @rin = rin.to_l
        @rix = rix.to_l
        @bvs = bvs.to_l
        @ipd = ipd.to_f
        txw, txh = txs.split(",")
        if txh
          @txs = [txw.to_l, txh.to_l]
        else
          @txs = txs.to_l
        end
        @twa = twa.to_f
        @r2r = r2r.to_f
        @rti = rti.to_l
        puts "Initialized parameters: GX=#{@GX}, GY=#{@GY}, GW=#{@GW}, GD=#{@GD}, BVS=#{@bvs}, CIG=#{@cig}"
      rescue => e
        puts "Error reading defaults: #{e.message}"
        Sketchup.write_default("FloorGenerator", "", @@opt)
        Sketchup.write_default("FloorGenerator", @@opt, @defaults)
        self.dialog
      end

      unless @@dlg_FG_Main
        @@dlg_FG_Main = UI::WebDialog.new("FloorGenerator", false, "BTW", 220, 600, 10, 10, true)
        @@dlg_FG_Main.set_html(
          "<html>
            <body style='background-color:powderblue'>
              <form style='font-family:#{@font};font-size:70%;color:black'>
                <fieldset>
                  <legend style='font-size:125%;color:red'><b> Pattern </b></legend>
                  <select onChange='patternchanged(value)'>
                    <option value='Brick' #{@@opt=='Brick' ? 'selected' : ''}>Brick</option>
                    <option value='Tile' #{@@opt=='Tile' ? 'selected' : ''}>Tile</option>
                    <option value='Wood' #{@@opt=='Wood' ? 'selected' : ''}>Wood</option>
                    <option value='Tweed' #{@@opt=='Tweed' ? 'selected' : ''}>Tweed</option>
                    <option value='Hbone' #{@@opt=='Hbone' ? 'selected' : ''}>Herringbone</option>
                    <option value='BsktWv' #{@@opt=='BsktWv' ? 'selected' : ''}>Basket Weave</option>
                    <option value='HpScth1' #{@@opt=='HpScth1' ? 'selected' : ''}>Hopscotch1</option>
                    <option value='HpScth2' #{@@opt=='HpScth2' ? 'selected' : ''}>HopScotch2</option>
                    <option value='HpScth3' #{@@opt=='HpScth3' ? 'selected' : ''}>HopScotch3</option>
                    <option value='HpScth4' #{@@opt=='HpScth4' ? 'selected' : ''}>HopScotch4</option>
                    <option value='IrPoly' #{@@opt=='IrPoly' ? 'selected' : ''}>Irregular Polygons</option>
                    <option value='Hexgon' #{@@opt=='Hexgon' ? 'selected' : ''}>Hexagons</option>
                    <option value='Octgon' #{@@opt=='Octgon' ? 'selected' : ''}>Octagons</option>
                    <option value='Wedge' #{@@opt=='Wedge' ? 'selected' : ''}>Wedges</option>
                    <option value='I_Block' #{@@opt=='I_Block' ? 'selected' : ''}>I_Block</option>
                    <option value='Diamonds' #{@@opt=='Diamonds' ? 'selected' : ''}>Diamonds</option>
                    <option value='Reset'>Reset</option>
                  </select>
                  <!-- Pattern Icons -->
                  #{@@opt=='Brick' ? "<img src='#{@icons}Brick.jpg' align='top'/>" : ''}
                  #{@@opt=='Tile' ? "<img src='#{@icons}Tile.jpg' align='top'/>" : ''}
                  #{@@opt=='Wood' ? "<img src='#{@icons}Wood.jpg' align='top'/>" : ''}
                  #{@@opt=='Tweed' ? "<img src='#{@icons}Tweed.jpg' align='top'/>" : ''}
                  #{@@opt=='Hbone' ? "<img src='#{@icons}Hbone.jpg' align='top'/>" : ''}
                  #{@@opt=='BsktWv' ? "<img src='#{@icons}BsktWv.jpg' align='top'/>" : ''}
                  #{@@opt=='HpScth1' ? "<img src='#{@icons}HpScth1.jpg' align='top'/>" : ''}
                  #{@@opt=='HpScth2' ? "<img src='#{@icons}HpScth2.jpg' align='top'/>" : ''}
                  #{@@opt=='HpScth3' ? "<img src='#{@icons}HpScth3.jpg' align='top'/>" : ''}
                  #{@@opt=='HpScth4' ? "<img src='#{@icons}HpScth4.jpg' align='top'/>" : ''}
                  #{@@opt=='IrPoly' ? "<img src='#{@icons}IrPoly.jpg' align='top'/>" : ''}
                  #{@@opt=='Hexgon' ? "<img src='#{@icons}Hexgon.jpg' align='top'/>" : ''}
                  #{@@opt=='Octgon' ? "<img src='#{@icons}Octgon.jpg' align='top'/>" : ''}
                  #{@@opt=='Wedge' ? "<img src='#{@icons}Wedge.jpg' align='top'/>" : ''}
                  #{@@opt=='I_Block' ? "<img src='#{@icons}I_Block.jpg' align='top'/>" : ''}
                  #{@@opt=='Diamonds' ? "<img src='#{@icons}Diamonds.jpg' align='top'/>" : ''}
                  <!-- Pattern Icons -->
                </fieldset>
              </form>
              <form style='font-family:#{@font};font-size:70%;color:black'>
                <fieldset>
                  <legend style='font-size:125%;color:red'><b> Size </b></legend>
                  <table style='font-size:100%'>
                    #{((@@opt!='Hexgon' && @@opt!='Octgon' && @@opt!='Diamonds')) ? '<!--' : ''}
                    <tr><td align='right' width=60>Side Length:</td>
                    <td><input type='text' name='BTL' value='#{@GX}' size=4 onChange='optionchanged(name,value)' /></td></tr>
                    #{((@@opt!='Hexgon' && @@opt!='Octgon' && @@opt!='Diamonds')) ? '-->' : ''}
                    #{(@@opt=='Hexgon' || @@opt=='Octgon' || @@opt=='IrPoly' || @@opt=='Diamonds') ? '<!--' : ''}
                    <tr><td align='right' width=54>Length:</td>
                    <td><input type='text' name='BTL' value='#{@GX}' size=4 onChange='optionchanged(name,value)' /></td>
                    #{@@opt=='Wood' ? ('<td><input type="checkbox" name="FLW" value="Yes" #{@flw=="Yes" ? "checked" : ""} onClick="optionchanged(name,value)">Fixed</td>') : ''}
                    </tr>
                    <tr><td align='right'>Width:</td>
                    <td><input type='text' name='BTW' value='#{@GY}' size=4 onChange='optionchanged(name,value)' /></td>
                    #{@@opt=='Wood' ? ('<td><input type="checkbox" name="FWW" value="Yes" #{@fww=="Yes" ? "checked" : ""} onClick="optionchanged(name,value)">Fixed</td>') : ''}
                    </tr>
                    #{(@@opt=='Hexgon' || @@opt=='Octgon' || @@opt=='IrPoly' || @@opt=='Diamonds') ? '-->' : ''}
                    <tr><td align='right' width=54>Gap Width:</td><td>
                    <input type='text' name='BGW' value='#{@GW}' size=4 onChange='optionchanged(name,value)' /></td></tr>
                    <tr><td align='right' width=54>Gap Depth:</td><td>
                    <input type='text' name='BGD' value='#{@GD}' size=4 onChange='optionchanged(name,value)' /></td><td>
                    <input type='checkbox' name='FWT' value='Yes' #{@fwt=='Yes' ? 'checked' : ''} onClick='optionchanged(name,value)'>Fixed
                    </td></tr>
                    #{@@opt!='Brick' && @@opt!='Tile' ? '<!--' : ''}
                    <tr><td align='right' width=54>\% Offset:</td>
                    <td><input type='text' name='R2R' value='#{r2r}' size=4 onChange='optionchanged(name,value)' /></td></tr>
                    #{@@opt!='Brick' && @@opt!='Tile' ? '-->' : ''}
                    #{@@opt!='Tweed' ? '<!--' : ''}
                    <tr><td align='right' width=54>Angle:</td>
                    <td><input type='text' name='TWA' value='#{@twa}' size=4 onChange='optionchanged(name,value)' /></td></tr>
                    #{@@opt!='Tweed' ? '-->' : ''}
                    #{@@opt!='BsktWv' ? '<!--' : ''}
                    <tr><td align='right' width=54>Weave Count:</td>
                    <td><input type='text' name='BWB' value='#{@bwb}' size=4 onChange='optionchanged(name,value)' /></td></tr>
                    #{@@opt!='BsktWv' ? '-->' : ''}
                    #{@@opt!='IrPoly' ? '<!--' : ''}
                    <td align='right' width=54>Pt Density(0.1-1.0)</td>
                    <td><input type='text' name='IPD' value='#{ipd}' size=2 onChange='optionchanged(name,value)'/></td></tr>
                    #{@@opt!='IrPoly' ? '-->' : '' }
                  </table>
                </fieldset>
                <fieldset>
                  <legend style='font-size:125%;color:red'><b> Options </b></legend>
                  #{@@opt=='IrPoly' ? '<!--' : ''}
                  <select name='ORG' style='width:90px' onChange='optionchanged(name,value)'>
                    <option value='Corner' #{@spt=='Corner' ? 'selected' : ''}>Corner</option>
                    <option value='Center' #{@spt=='Center' ? 'selected' : ''}>Center</option>
                  </select> : Grid Origin<br>
                  <select name='ROT' style='width:90px' onChange='optionchanged(name,value)'>
                    <option value='0' #{@rot=='0' ? 'selected' : ''}>0</option>
                    <option value='45' #{@rot=='45' ? 'selected' : ''}>45</option>
                    <option value='90' #{@rot=='90' ? 'selected' : ''}>90</option>
                  </select> : Grid Rotation<br>
                  #{@@opt=='IrPoly' ? '-->' : ''}
                  <select name='MAT' style='width:90px' onChange='optionchanged(name,value)'>
                    <option value='Current' #{@app=='Current' ? 'selected' : ''}>Current</option>
                    <option value='Rand_Clr' #{@app=='Rand_Clr' ? 'selected' : ''}>Rand_Clr</option>
                    <option value='Rand_Tex' #{@app=='Rand_Tex' ? 'selected' : ''}>Rand_Tex</option><br>
                  </select> : Material#{@app!='Rand_Tex' ? '<!--' : '<br>'}
                    <button id='RTS' onclick='ChangeSource(id)'>Source</button>#{@app!='Rand_Tex' ? '-->' : ''}<br><hr>
                  <input type='text' name='RDS' value='#{rds}' size=2 onChange='optionchanged(name,value)'/> : Random Seed<br><hr>
                  <input type='text' name='TSZ' value='#{txs}' size=5 onChange='optionchanged(name,value)'/> : Texture Size (w,h)<br>
                  #{@@opt=='Hexgon' || @@opt=='Octgon' || @@opt=='IrPoly' ? '<!--' : ''}
                  <input type='checkbox' name='ATE' value='Yes' #{@ate=='Yes' ? 'checked' : ''} onClick='optionchanged(name,value)'>Align Texture to Longest Edge<br>
                  #{@@opt=='Hexgon' || @@opt=='Octgon' || @@opt=='IrPoly' ? '-->' : ''}
                  <input type='checkbox' name='WIG' value='Yes' #{@rtt=='Yes' ? 'checked' : ''} onClick='optionchanged(name,value)'>Random Position Texture </input>
                  #{@rtt=='No' ? '<!--' : ''}
                  Inc: <input type='text' name ='RTI' value='#{@rti}' size=3 onchange='optionchanged(name,value)'/>
                  #{@rtt=='No' ? '-->' : ''}<br>
                  <select name='WAG' style='width:60px' onChange='optionchanged(name,value)'>
                    <option value='No' #{@rtr=='No' ? 'selected' : ''}>No</option>
                    <option value='30' #{@rtr=='30' ? 'selected' : ''}>30</option>
                    <option value='45' #{@rtr=='45' ? 'selected' : ''}>45</option>
                    <option value='90' #{@rtr=='90' ? 'selected' : ''}>90</option>
                    <option value='180' #{@rtr=='180' ? 'selected' : ''}>180</option>
                    <option value='Rand' #{@rtr=='Rand' ? 'selected' : ''}>Rand</option>
                  </select> : Random Rotation<br><hr>
                  #{@@opt=='Wood' ? '<!--' : ''}
                  <input type='checkbox' name='WOB' value='Yes' #{@rfr=='Yes' ? 'checked' : ''} onClick='optionchanged(name,value)'/>Random Imperfections<br>
                  #{@@opt=='Wood' ? '-->' : ''}
                  #{@rfr!='Yes' ? '<!--' : ''}
                  Min:<input type='text' name='RIn' value='#{@rin}' size=4 onChange='optionchanged(name,value)'/>
                  Max:<input type='text' name='RIx' value='#{@rix}' size=4 onChange='optionchanged(name,value)'/> <br>
                  #{@rfr!='Yes' ? '-->' : ''}
                  <input type='checkbox' name='BVL' value='Yes' #{@bev=='Yes' ? 'checked' : ''} onClick='optionchanged(name,value)'/>Add Bevel to #{@@opt}<br>
                  #{@bev!='Yes' ? '<!--' : ''}
                  Size:<input type='text' name='BVS' value='#{@bvs}' size=4 onChange='optionchanged(name,value)'/><br>
                  #{@bev!='Yes' ? '-->' : ''}
                  <input type='checkbox' name='CBF' value='Yes' #{@cbf=='Yes' ? 'checked' : ''} onClick='optionchanged(name,value)'/>Create Behind Face<br>
                  <input type='checkbox' name='CIG' value='Yes' #{@cig=='Yes' ? 'checked' : ''} onClick='optionchanged(name,value)'/>Create Individual Groups<br>
                </fieldset>
              </form>
              <script type='text/javascript'>
                function patternchanged(value) {
                  window.location='skp:PatternChanged@'+value;
                };
                function optionchanged(name,value) {
                  window.location='skp:OptionChanged@'+name+'='+value;
                };
                function ChangeSource() {
                  window.location='skp:ChangeSource@';
                };
              </script>
            </body>
          </html>"
        )

        @@dlg_FG_Main.add_action_callback("OptionChanged") { |d, p|
          var, val = p.split("=")
          update = false
          case var
          when "BTL" then @GX = val.to_l
          when "BTW" then @GY = val.to_l
          when "BGW" then @GW = val.to_l; @HW = @GW / 2.0
          when "BGD" then @GD = val.to_l
          when "BWB" then @bwb = val.to_i
          when "ORG" then @spt = val
          when "ROT" then @rot = val
          when "MAT" then @app = val; update = true; self.source_of_textures if @app == 'Rand_Tex'
          when "IPD" then @ipd = val.to_f; @ipd = [@ipd, 0.1].max; @ipd = [@ipd, 1.0].min
          when "FLW" then @flw == "Yes" ? @flw = "No" : @flw = "Yes"
          when "FWW" then @fww == "Yes" ? @fww = "No" : @fww = "Yes"
          when "FWT" then @fwt == "Yes" ? @fwt = "No" : @fwt = "Yes"
          when "RDS" then @rds = val.to_i
          when "TSZ" then @tsz = val
          when "WAG" then @rtr = val
          when "ATE" then @ate == "Yes" ? @ate = "No" : @ate = "Yes"
          when "WIG" then @rtt == "Yes" ? @rtt = "No" : @rtt = "Yes"; update = true
          when "RTI" then @rti = val.to_l; @rti > 0 ? @rtt = "Yes" : @rtt = "No"
          when "WOB" then @rfr == "Yes" ? @rfr = "No" : @rfr = "Yes"; update = true
          when "BVL" then @bev == "Yes" ? @bev = "No" : @bev = "Yes"; update = true
          when "R2R" then @r2r = val.to_f; r2r = val
          when "TWA" then @twa = val.to_f
          when "RIn" then @rin = val.to_l; @rin = [@rin, 0].max
          when "RIx" then @rix = val.to_l; @rix = [@rix, @GD].min
          when "BVS" then @bvs = val.to_l
          when "CBF" then @cbf == "Yes" ? @cbf = "No" : @cbf = "Yes"
          when "CIG" then @cig == "Yes" ? @cig = "No" : @cig = "Yes"
          end

          tbx = @GX.to_s.gsub('"', '\"')
          tby = @GY.to_s.gsub('"', '\"')
          twa = @twa.to_s
          @txs = nil
          rds = @rds.to_s
          (txw, txh = @tsz.split(","); @txs = [txw.to_l, txh.to_l] if txh) if @tsz && @tsz != "0"
          gw = @GW.to_s.gsub('"', '\"')
          gd = @GD.to_s.gsub('"', '\"')
          txs = @tsz.gsub('"', '\"') if @tsz
          bwb = @bwb.to_s
          rin = @rin.to_s.gsub('"', '\"')
          rix = @rix.to_s.gsub('"', '\"')
          bvs = @bvs.to_s.gsub('"', '\"')
          ipd = @ipd.to_s
          rti = @rti.to_s.gsub('"', '\"')
          if @separator == ','
            tbx.gsub!('.', ',')
            tby.gsub!('.', ',')
            gw.gsub!('.', ',')
            gd.gsub!('.', ',')
            txs.gsub!('.', ',')
            rin.gsub!('.', ',')
            rix.gsub!('.', ',')
            bvs.gsub!('.', ',')
            rti.gsub!('.', ',')
          end
          @defaults = [@spt, @rot, @app, @flw, @fww, r2r, @rtt, @rtr, txs, @rfr, @bev, twa, tbx, tby, gw, gd, bwb, @ate, @fwt, rds, rin, rix, bvs, ipd, rti, @cbf, @cig]
          Sketchup.write_default("FloorGenerator", @@opt, @defaults)
          (@dlg_update = true; @@dlg_FG_Main.close; @@dlg_FG_Main = nil; @dlg_update = false; self.dialog) if update
        }

        @@dlg_FG_Main.add_action_callback("PatternChanged") { |d, p|
          @@opt = p
          if @@opt == "Reset"
            ["Brick", "Tile", "Wood", "Tweed", "Hbone", "BsktWv", "HpScth1", "HpScth2", "Rand_Tex"].each { |o| Sketchup.write_default("FloorGenerator", o, nil) }
            ["HpScth3", "HpScth4", "IrPoly", "Hexgon", "Octgon", "Wedge", "I_Block", "Diamonds"].each { |o| Sketchup.write_default("FloorGenerator", o, nil) }
            @@opt = "Tile"
          end
          Sketchup.write_default("FloorGenerator", "", @@opt)
          @dlg_update = true
          @@dlg_FG_Main.close
          @@dlg_FG_Main = nil
          @dlg_update = false
          self.dialog
          self.source_of_textures if @app == "Rand_Tex"
        }

        @@dlg_FG_Main.add_action_callback("ChangeSource") { |d, p|
          self.source_of_textures
        }

        @@dlg_FG_Main.set_on_close { onCancel(nil, nil) unless @dlg_update }

        RUBY_PLATFORM =~ /(darwin)/ ? @@dlg_FG_Main.show_modal() : @@dlg_FG_Main.show()
      end
    end

    def onMouseMove(flags, x, y, view)
      @ip.pick view, x, y
      view.tooltip = @ip.tooltip
      view.refresh
      Sketchup::set_status_text "Select Grid Pattern, change options or sizes if needed then select Face for #{@@opt} pattern"
    end

	def onLButtonDown(flags, x, y, view)
		ph = view.pick_helper
		ph.do_pick x, y
		face = ph.best_picked
		@cp = @ip.position
		if face.is_a?(Sketchup::Face)
		  dmax = [@GX, @GY].max
		  if face.bounds.diagonal >= dmax
			unless @@opt == "BsktWv" || @@opt == 'Hexgon' || @@opt == 'Octgon' || @@opt == 'IrPoly' || @@opt == 'Diamonds'
			  torb = (face.area / (@GX * @GY)).ceil
			  if (@GX <= 1 || @GY <= 1) || (torb > 500)
				return if UI.messagebox("Tile dimensions may be too small. #{torb} #{@@opt} needed. Continue?", MB_YESNO) == 7
				view.refresh
			  end
			end
			@mod.start_operation "FloorGenerator", true
			eye = @vue.camera.eye
			ctr = face.bounds.center
			@rds > 0 ? srand(@rds) : srand
			face.reverse! if ((ctr.vector_to(eye)).angle_between(face.normal)) > Math::PI / 2.0
			@edges = face.edges
			@norm = face.normal
			l = 0
			fpts = []
			lpts = []
	  
			@front_mat = face.material
			@back_material = face.back_material
	  
			if @@opt == "Brick"
			  for loop in face.loops
				for v in loop.vertices
				  lpts << v.position if v.position
				end
				fpts[l] = lpts
				lpts = []
				l += 1
			  end
			end
	  
			if self.grid_data(face)
			  @mat = @mod.materials.current
			  @mat = face.back_material if face.back_material
			  @mat = face.material if face.material
	  
			  @ent.erase_entities(face) if face.valid?
			  existing_faces = @ent.grep(Sketchup::Face)
			  dump = @egrp.explode
			  dump.grep(Sketchup::Edge).each { |e| e.find_faces }
			  created_faces = @ent.grep(Sketchup::Face) - existing_faces
			  cnt = 0
			  max = created_faces.length
			  new_faces = []
			  @rds > 0 ? srand(@rds) : srand
			  fgrp = @ent.add_group
			  @fge = fgrp.entities
			  @fgt = fgrp.transformation
			  @app = "current" if @app == 'Rand_Tex' && @textures.length == 0
	  
			  created_faces.each do |f|
				cnt += 1
				self.progress_bar(cnt, max, "#{@@opt} offsets")
				next unless f.valid?
				f.reverse! unless f.normal.samedirection? @norm
				pts = @GW > 0 ? self.g_offset(f, @HW) : f.outer_loop.vertices.map { |v| v.position }
				if pts && pts.length >= 3
				  g = @fge.add_group
				  ge = g.entities
				  new_face = ge.add_face(pts)
				  next unless new_face && new_face.valid?
				  new_face.reverse! unless new_face.normal.samedirection?(@norm)
				  self.paint_it(new_face)
				  old = ge.grep(Sketchup::Face)
	  
				  # 確保 gd 是有效的 Length 類型
				  gd = @fwt == 'Yes' ? @GD : (@GD + (@GD * rand * (rand <=> 0.5)))
				  unless gd.is_a?(Length)
					gd = gd.to_l rescue 0.to_l
					puts "Converted gd to Length: #{gd}" if gd > 0
				  end
				  if gd > 0
					begin
					  puts "Before pushpull: face valid? #{new_face.valid?}, gd: #{gd}, normal: #{new_face.normal}, parent entities: #{new_face.parent}"
					  new_face.pushpull(gd, false)
					  puts "Pushpull successful for face"
					rescue => e
					  puts "Pushpull failed: #{e.message}"
					end
				  else
					puts "Invalid gap depth: #{gd}"
				  end
	  
				  new = ge.grep(Sketchup::Face) - old
				  new.reject! { |nf| !nf.normal.parallel?(@norm) }
				  if new.length == 1
					face = new[0]
					self.wig(face) if @rtt == "Yes" && @rti > 0
					self.wag(face) unless @rtr == "No"
					self.wob(g, -1) if @rfr == "Yes"
					self.bev(face, @bvs) if @bev == "Yes"
				  else
					puts "No new face created after pushpull"
				  end
	  
				  # 根據 CIG 設置決定是否爆炸組
				  g.explode unless @cig == 'Yes'
				else
				  puts "Failed to generate points for face offset"
				end
			  end
	  
			  Sketchup.set_status_text "finishing and cleaning up"
			  dump.each { |e| @ent.erase_entities(e) if e.valid? && e.is_a?(Sketchup::Edge) }
	  
			  if @@opt == "Brick"
				for i in 0...fpts.length
				  f = @fge.add_face(fpts[i]) if fpts[i] && !fpts[i].empty?
				  @fge.erase_entities(f) if i > 0 && f&.valid?
				end
			  end
	  
			  if @cbf == 'Yes'
				cf = (@ent.grep(Sketchup::Face) - existing_faces)[0]
				if cf && cf.valid?
				  for l in cf.loops
					nf = @fge.add_face(l.vertices.map { |v| v.position.transform(@fgt.inverse) })
					l.outer? ? nf.reverse! : nf.erase! if nf&.valid?
				  end
				  drop = @bev == 'Yes' ? (@GD + @bvs) : @GD
				  vector = @norm.reverse
				  vector.length = drop
				  @ent.transform_entities(Geom::Transformation.new(vector), fgrp)
				  edges = cf.edges
				  cf.erase! if cf.valid?
				  edges.each { |e| @ent.erase_entities(e) if e.valid? && e.faces.length == 0 }
				else
				  puts "No face found for Create Behind Face"
				end
			  end
	  
			  if fgrp.valid?
				puts "Final group created with #{@fge.grep(Sketchup::Group).length} sub-groups"
			  else
				puts "Final group is invalid"
			  end
			  @mod.commit_operation
			else
			  puts "Grid data generation failed"
			end
			@last_opt = @@opt
		  else
			UI.messagebox "This face is too small for a #{@GX} X #{@GY} #{@@opt} pattern."
			return false
		  end
		end
	  end

    def onRButtonDown(flags, x, y, view)
      onCancel(flags, view)
    end

    def onCancel(flags, view)
      Sketchup.send_action "selectSelectionTool:"
    end

    def deactivate(view)
      @dlg_FG_Picker.close if @dlg_FG_Picker
      @@dlg_FG_Main.close
      @@dlg_FG_Main = nil
      Sketchup.active_model.options["UnitsOptions"]["LengthUnit"] = @current_units
      Sketchup.active_model.options["UnitsOptions"]["LengthPrecision"] = @current_precision
    end

    def draw(view)
      if @ip.valid? && @ip.display?
        @ip.draw(view)
      end
      if @ip.face
        pts = @ip.face.outer_loop.vertices.map { |v| v.position }
        view.line_width = 3
        view.drawing_color = 'yellow'
        view.draw GL_LINE_LOOP, pts
      end
    end

    def source_of_textures
      ans = UI.inputbox(["Materials From:"], ["Folder"], ["Folder|Model"], "Random Textures Source")
      if ans
        @dlg_FG_Picker.close if @dlg_FG_Picker
        case ans[0]
        when "Folder" then self.materials_from_file; @options = @textures_from_file; self.pickMaterials
        when "Model" then @options = Sketchup.active_model.materials.map { |m| m.name }; self.pickMaterials
        end
      end
    end

    def materials_from_file
      @textures_from_file = []
      @images = []
      @image_path = File.dirname(__FILE__) + "/BTW_Textures/*.*"
      @image_path = Sketchup.read_default("FloorGenerator", "Rand_Tex", @image_path)
      @image_path = UI.openpanel("Random Texture Files", @image_path)
      unless @image_path.nil?
        image_folder = File.dirname(@image_path.gsub('\\', '/'))
        @images = []
        @images = Dir[image_folder + "/*.{jpg,png,tif,bmp,gif,tga,epx}"]
        @images.each { |i| @textures_from_file << File.basename(i, '.*') }
        if @textures_from_file[0]
          @textures_from_file.each_with_index { |name, i|
            unless @mod.materials[name]
              mat = @mod.materials.add(name)
              mat.texture = @images[i]
              mat.texture.size = @txs if @txs && @txs != 0
            end
          }
          Sketchup.write_default("FloorGenerator", "Rand_Tex", image_folder + "/*.*")
        else
          @app = "current"
        end
      else
        @app = "current"
      end
    end

    def pickMaterials
      @dlg_FG_Picker = UI::WebDialog.new("Material Picker", false, "WDID", 300, 200, 10, 10, true)
      html = <<-HTML
      <!DOCTYPE html>
      <html lang="en-US">
        <head>
          <meta charset="utf-8" />
          <meta content="IE=edge" http-equiv="X-UA-Compatible" />
        </head>
        <body>
          <form action='skp:selectMaterials@'>
            <select id='list' name='Material' multiple ></select>
            <br><br><input type='submit' name='submit' value='Select' /><br>
          </form>
          <script>
            function addToList(id,options) {
              var x = document.getElementById(id);
              for (i=0;i<options.length;i++) {
                var option=document.createElement('option');
                option.text=options[i];
                x.add(option);
              };
              x.selectIndex=0;
            };
          </script>
          <script>
            window.location='skp:InitializeForm@';
          </script>
        </body>
      </html>
      HTML

      @dlg_FG_Picker.set_html(html)
      RUBY_PLATFORM =~ /(darwin)/ ? @dlg_FG_Picker.show_modal() : @dlg_FG_Picker.show()

      @dlg_FG_Picker.add_action_callback("InitializeForm") {
        @dlg_FG_Picker.execute_script("addToList('list',#{@options});")
      }

      @dlg_FG_Picker.add_action_callback("selectMaterials") { |d, p|
        p.gsub!("?", "")
        tokens = p.split("&")
        @textures = []
        tokens.each { |t|
          var, val = t.split("=")
          @textures << val if var == 'Material'
        }
      }
    end

    def grid_data(face)
      pts = face.outer_loop.vertices.collect { |v| v.position }
      ndx = 0
      cp = 1e6
      ls = 0.0
      lp = pts.length - 1
      pts.each_with_index { |p, i| d = p.distance(pts[i-1]) + p.distance(pts[i-lp]); ndx = i if d > ls; ls = [ls, d].max }
      ctr = face.bounds.center
      ctr = ctr.project_to_plane face.plane unless ctr.on_plane? face.plane
      d1 = pts[ndx].distance(pts[ndx-lp])
      d2 = pts[ndx].distance(pts[ndx-1])
      if d1 >= d2
        @v1 = pts[ndx].vector_to(pts[ndx-lp]).normalize
        pol = ctr.project_to_line([pts[ndx], pts[ndx-lp]])
        rot = @rot.to_f
        @dx = d1
        @dy = d2
      else
        @v1 = pts[ndx].vector_to(pts[ndx-1]).normalize
        pol = ctr.project_to_line([pts[ndx], pts[ndx-1]])
        rot = -@rot.to_f
        @dx = d2
        @dy = d1
      end

      @v2 = pol.vector_to(ctr).normalize
      @v3 = face.normal

      unless @@opt == 'IrPoly'
        if @rot != "0"
          tr = Geom::Transformation.rotation(ctr, @norm, rot.degrees)
          @v1.transform! tr
          @v2.transform! tr
        end

        pts.each_with_index { |p, i| d = p.distance(@cp); ndx = i if d < cp; cp = [cp, d].min }
        @cor = pts[ndx]

        dx = @GX + @GW
        dy = @GY + @GW
        nx = (face.bounds.diagonal * 1.5 / dx).ceil
        ny = (face.bounds.diagonal * 1.5 / dy).ceil
        pt0 = ctr.offset(@v1, -dx * (nx / 2)).offset(@v2, -dy * (ny / 2))

        @data = []
        row = []
        cnt = 0
        max = nx * ny

        case @@opt
        when "Wood"
          yd = 0.0
          nx *= 2 if @flw == "No"
          ny *= 2 if @fww == "No"
          @rds > 0 ? srand(@rds) : srand
          for i in 0..ny
            p0 = row[0] = pt0.offset(@v2, yd)
            d = 0.0
            ty = dy
            for j in 1..nx
              tx = dx
              if j == 1
                begin
                  tx = rand * dx
                end until tx >= dx * 0.25 && tx <= dx * 0.75
              else
                unless @flw == "Yes"
                  begin
                    tx = rand * dx
                  end until tx >= dx * 0.75
                end
              end
              d += tx
              row[j] = p0.offset(@v1, d)
            end
            unless @fww == "Yes"
              begin
                ty = rand * dy
              end until ty >= dy * 0.5
            end
            row.push ty
            yd += ty
            @data[i] = row
            row = []
          end
        when "Tweed"
          dx = @GY + @GW
          dy = @GX + @GW
          xd = dx / Math.cos(@twa.degrees)
          yd = dy * Math.cos(@twa.degrees)
          xx = dy * Math.sin(@twa.degrees)
          ny = ((face.bounds.diagonal * 1.5) / yd).ceil
          nx = ((face.bounds.diagonal * 1.5) / xd).ceil
          pt0 = ctr.offset(@v1, -(xd * (nx / 2))).offset(@v2, -(yd * (ny / 2)))
          for i in 0..ny
            row[0] = pt0.offset(@v2, yd * i)
            row[0].offset!(@v1, -xx) if i % 2 == 1
            for j in 1..nx
              row[j] = row[j-1].offset(@v1, xd)
            end
            @data[i] = row
            row = []
          end
        end
      end

      case @@opt
      when "Brick", "Tile" then self.brick_tile(face, dx, dy, nx, ny, pt0)
      when "Wood" then self.wood(face, nx, ny)
      when "Tweed" then self.tweed(face, nx, ny)
      when "Hbone" then self.hbone(face)
      when "BsktWv" then self.bsktwv(face, dx, dy)
      when "HpScth1" then self.hopscotch(face, dx, dy)
      when "HpScth2" then self.hopscotch2(face, dx, dy)
      when 'HpScth3' then self.hopscotch3(face)
      when "HpScth4" then self.hopscotch4(face, dx, dy)
      when "Hexgon" then self.hexagon(face, @GX)
      when "Octgon" then self.octagon(face, @GX)
      when "IrPoly" then self.irregular_polygons(face)
      when "Wedge" then self.wedge(face, dx, dy)
      when "I_Block" then self.i_block(face, dx, dy)
      when "Diamonds" then self.diamonds(face, @GX)
      else
        puts "#{@@opt} not found"
        return false
      end
      return true
    end

    def brick_tile(f, dx, dy, nx, ny, pt0)
      tg = @ent.add_group
      tge = tg.entities
      tgt = tg.transformation
      fg = @ent.add_group f
      cnt = 0
      max = nx * ny
      md = 1e9
      for i in 0..ny+1
        p0 = pt0.offset(@v2, dy * i)
        p1 = p0.offset(@v1, dx * nx)
        tge.add_face(self.makeaface(p0, p1, @norm))
        unless i > 0
          p1 = p0.offset(@v2, dy * ny)
          tge.add_face(self.makeaface(p0, p1, @norm))
        end
      end
      cnt = 0
      max = nx * ny
      for i in 0..ny
        p0 = pt0.offset(@v2, dy * i)
        i > 0 ? xd = ((i * @r2r) % 100 / 100.0) * dx : xd = dx
        for j in 0..nx
          cnt += 1
          self.progress_bar(cnt, max, "#{@@opt} Grid")
          p1 = p0.offset(@v1, xd)
          xd = dx
          p2 = p1.offset(@v2, dy)
          tge.add_face(self.makeaface(p1, p2, @norm))
          (d = @cor.distance(p0); (cpt = p0; md = d) if md > d) if @spt == "Corner" && i > 0
          p0 = p1
        end
      end
      (tr = Geom::Transformation.new(cpt.vector_to(@cor)); tge.transform_entities(tr, tge.to_a)) if @spt == "Corner"
      @egrp = @ent.add_group
      @ege = @egrp.entities
      @egt = @egrp.transformation
      Sketchup::set_status_text "Intersecting Grid and Face"
      tge.intersect_with(true, tgt, @ege, @egt, false, fg)
      fg.explode
      tg.erase! unless $sdm_debug
    end

    def wood(f, nx, ny)
      tg = @ent.add_group
      tge = tg.entities
      tgt = tg.transformation
      fg = @ent.add_group f
      cnt = 0
      max = nx * ny
      md = 1e9
      for i in 0...ny
        dy = @data[i][-1]
        for j in 1..nx
          cnt += 1
          self.progress_bar(cnt, max, "Wood grid")
          tge.add_face(self.makeaface(@data[i][j-1], @data[i][j], @norm))
          tge.add_face(self.makeaface(@data[i][j], @data[i][j].offset(@v2, dy), @norm))
          (d = @cor.distance(@data[i][j-1]); (cpt = @data[i][j-1]; md = d) if md > d) if @spt == "Corner" && i > 0
        end
      end
      (tr = Geom::Transformation.new(cpt.vector_to(@cor)); tge.transform_entities(tr, tge.to_a)) if @spt == "Corner"
      @egrp = @ent.add_group
      @ege = @egrp.entities
      @egt = @egrp.transformation
      Sketchup::set_status_text "Intersecting Grid and Face"
      tge.intersect_with(true, tgt, @ege, @egt, false, fg)
      fg.explode
      tg.erase! unless $sdm_debug
    end

    def tweed(f, nx, ny)
      tg = @ent.add_group
      tge = tg.entities
      tgt = tg.transformation
      fg = @ent.add_group f
      cnt = 0
      max = nx * ny
      md = 1e9
      for i in 1..ny
        for j in 1..nx
          cnt += 1
          self.progress_bar(cnt, max, "Tweed grid")
          tge.add_face(self.makeaface(@data[i-1][j-1], @data[i][j-1], @norm))
          tge.add_face(self.makeaface(@data[i-1][j-1], @data[i-1][j], @norm))
          (d = @cor.distance(@data[i-1][j-1]); (cpt = @data[i-1][j-1]; md = d) if md > d) if @spt == "Corner" && i > 1
        end
        tge.add_face(self.makeaface(@data[i-1][nx], @data[i][nx], @norm))
      end
      (tr = Geom::Transformation.new(cpt.vector_to(@cor)); tge.transform_entities(tr, tge.to_a)) if @spt == "Corner"
      @egrp = @ent.add_group
      @ege = @egrp.entities
      @egt = @egrp.transformation
      Sketchup::set_status_text "Intersecting Grid and Face"
      tge.intersect_with(true, tgt, @ege, @egt, false, fg)
      fg.explode
      tg.erase! unless $sdm_debug
    end

    def hbone(f)
      dx = @GY + @GW
      dy = @GX + @GW
      ctr = f.bounds.center
      ny = ((f.bounds.diagonal * 1.2) / (dy * 0.707107)).ceil
      nx = ((f.bounds.diagonal * 1.2) / (dx / 0.707107)).ceil
      pt = ctr.offset(@v1, -((dx / 0.707107) * (nx / 2))).offset(@v2, -((dy / 0.707107) * (ny / 2)) / 2)
      vup = @v1.transform Geom::Transformation.rotation(pt, @norm, 45.degrees)
      vdn = @v1.transform Geom::Transformation.rotation(pt, @norm, -45.degrees)
      fg = @ent.add_group f
      fgt = fg.transformation
      fg.name = "Face"
      tg = @ent.add_group
      tge = tg.entities
      tgt = tg.transformation
      xv = @v1
      xv.length = dx / 0.707107
      yv = @v2
      yv.length = dy / 0.707107
      cnt = 0
      max = nx * ny
      md = 1e9
      gp = pt
      p0 = pt
      for i in 0..ny/2
        for j in 0..nx
          cnt += 1
          self.progress_bar(cnt, max, "H'bone grid")
          p1 = p0.offset(vdn, dy)
          tge.add_face(self.makeaface(p0, p1, @norm))
          p2 = p1.offset(vup, dx)
          tge.add_face(self.makeaface(p1, p2, @norm))
          p3 = p2.offset(vdn, -dy)
          tge.add_face(self.makeaface(p2, p3, @norm))
          tge.add_face(self.makeaface(p3, p0, @norm))
          cnt += 1
          self.progress_bar(cnt, max, "H'bone grid")
          p1 = p0.offset(vup, dy)
          tge.add_face(self.makeaface(p0, p1, @norm))
          p2 = p1.offset(vdn, -dx)
          tge.add_face(self.makeaface(p1, p2, @norm))
          p3 = p2.offset(vup, -dy)
          tge.add_face(self.makeaface(p2, p3, @norm))
          tge.add_face(self.makeaface(p3, p0, @norm))
          (d = @cor.distance(gp); (cpt = gp; md = d) if md > d) if @spt == "Corner" && i > 0
          p0 += xv
          gp += xv
        end
        pt.offset!(yv)
        gp = pt
        p0 = pt
      end
      (tr = Geom::Transformation.new(cpt.vector_to(@cor)); tge.transform_entities(tr, tge.to_a)) if @spt == "Corner"
      @egrp = @ent.add_group
      @ege = @egrp.entities
      @egt = @egrp.transformation
      Sketchup::set_status_text "Intersecting Grid and Face"
      tge.intersect_with true, tgt, @ege, @egt, false, fg
      fg.explode
      tg.erase! unless $sdm_debug
    end

    def bsktwv(face, dx, dy)
      @bwb = 3 unless [2, 3, 4].include?(@bwb)
      if dx == @GW
        del = dy * @bwb * 2
      elsif dy == @GW
        del = dx * 2
      else
        del = [dx, dy * @bwb].max
        if del == dx
          dy = dx / @bwb
          del = dx * 2
        else
          dx = dy * @bwb
          del = dx * 2
        end
      end
      name = "BW-#{dx.to_l}X#{dy.to_l}X#{@bwb}"
      unless @mod.definitions[name]
        bw = @mod.definitions.add(name)
        be = bw.entities
        pts = []
        pts[0] = Geom::Point3d.new()
        v1 = [1, 0, 0]
        v2 = [0, 1, 0]
        norm = [0, 0, 1]
        tr = Geom::Transformation.new(pts[0], norm, 90.degrees)
        for i in 0..@bwb-1
          pts << pts[i].offset(v2, dy)
        end
        pts << pts[@bwb].offset(v1, dx)
        for i in @bwb+1..@bwb*2
          pts << pts[i].offset(v2, -dy)
        end
        for n in 1..4
          case @bwb
          when 2
            be.add_face(self.makeaface(pts[0], pts[2], norm))
            be.add_face(self.makeaface(pts[2], pts[3], norm))
            be.add_face(self.makeaface(pts[3], pts[5], norm))
            be.add_face(self.makeaface(pts[1], pts[4], norm))
          when 3
            be.add_face(self.makeaface(pts[0], pts[3], norm))
            be.add_face(self.makeaface(pts[3], pts[4], norm))
            be.add_face(self.makeaface(pts[4], pts[7], norm))
            be.add_face(self.makeaface(pts[1], pts[6], norm))
            be.add_face(self.makeaface(pts[2], pts[5], norm))
          when 4
            be.add_face(self.makeaface(pts[0], pts[4], norm))
            be.add_face(self.makeaface(pts[4], pts[5], norm))
            be.add_face(self.makeaface(pts[5], pts[9], norm))
            be.add_face(self.makeaface(pts[1], pts[8], norm))
            be.add_face(self.makeaface(pts[2], pts[7], norm))
            be.add_face(self.makeaface(pts[3], pts[6], norm))
          end
          pts.each { |p| p.transform! tr }
        end
        ci = @ent.add_instance(@mod.definitions[name], pts[0])
        ci.erase!
      end
      cmp = @mod.definitions[name]
      ctr = face.bounds.center
      diag = face.bounds.diagonal * 1.5
      del = dx * 2
      ny = nx = (diag / del).ceil
      md = 1e9
      cnt = 0
      max = nx * ny
      org = ctr.offset(@v1, -(del * (nx / 2))).offset(@v2, -(del * (ny / 2)))
      tg = @ent.add_group
      tge = tg.entities
      tgt = tg.transformation
      for i in 0..ny
        p0 = org.offset(@v2, del * i)
        for j in 0..nx
          cnt += 1
          self.progress_bar(cnt, max, "BasketWeave Grid")
          pt = p0.offset(@v1, del * j)
          (d = @cor.distance(pt); (cpt = pt; md = d) if md > d) if @spt == "Corner" && i > 0
          ci = tge.add_instance(cmp, Geom::Transformation.axes(pt, @v1, @v2, @norm))
        end
      end
      fg = @ent.add_group face
      (tr = Geom::Transformation.new(cpt.vector_to(@cor)); tge.transform_entities(tr, tge.to_a)) if @spt == "Corner"
      @egrp = @ent.add_group
      @ege = @egrp.entities
      @egt = @egrp.transformation
      Sketchup::set_status_text "Intersecting Grid and Face"
      tge.intersect_with true, tgt, @ege, @egt, false, fg
      fg.explode
      tg.erase! unless $sdm_debug
    end

    def hopscotch(face, dx, dy)
      hx = dx / 2.0
      hy = dy / 2.0
      name = "HS1-#{dx.to_l}x#{dy.to_l}"
      cmp = @mod.definitions[name]
      unless cmp
        p0 = Geom::Point3d.new()
        v1 = [1, 0, 0]
        v2 = [0, 1, 0]
        norm = [0, 0, 1]
        cmp = @mod.definitions.add(name)
        cpe = cmp.entities
        p1 = p0.offset(v2, dy)
        cpe.add_face(self.makeaface(p0, p1, norm))
        p2 = p1.offset(v1, dx)
        cpe.add_face(self.makeaface(p1, p2, norm))
        p3 = p2.offset(v1, hx)
        cpe.add_face(self.makeaface(p2, p3, norm))
        p4 = p3.offset(v2, -hy)
        cpe.add_face(self.makeaface(p3, p4, norm))
        p5 = p4.offset(v1, -hx)
        cpe.add_face(self.makeaface(p4, p5, norm))
        p6 = p2.offset(v2, -dy)
        cpe.add_face(self.makeaface(p2, p6, norm))
        cpe.add_face(self.makeaface(p6, p0, norm))
        ci = @ent.add_instance(cmp, p0)
        ci.erase!
      end
      ctr = face.bounds.center
      dxx = dx + dx + hx
      tg = @ent.add_group
      tge = tg.entities
      tgt = tg.transformation
      nx = (face.bounds.diagonal * 1.2 / dxx).ceil
      ny = (face.bounds.diagonal * 1.2 / hy).ceil
      pt0 = ctr.offset(@v1, -(dxx * (nx / 2))).offset(@v2, -(hy * (ny / 2)))
      cnt = 0
      max = nx * ny
      md = 1e9
      pt = pt0.clone
      for i in 0..ny
        for j in 0..nx
          cnt += 1
          self.progress_bar(cnt, max, "Hopscotch Grid")
          ci = tge.add_instance(cmp, Geom::Transformation.axes(pt, @v1, @v2, @norm))
          pt.offset!(@v1, dxx)
          (d = @cor.distance(pt); (cpt = pt.clone; md = d) if md > d) if @spt == "Corner" && i > 0
        end
        case i % 5
        when 0 then pt = pt0.offset(@v1, -dx).offset(@v2, hy)
        when 1 then pt = pt0.offset(@v1, hx).offset(@v2, dy)
        when 2 then pt = pt0.offset(@v1, -hx).offset(@v2, dy + hy)
        when 3 then pt = pt0.offset(@v1, dx).offset(@v2, dy * 2)
        when 4 then pt = pt0.offset(@v2, dy * 2 + hy); pt0.offset!(@v2, dy * 2 + hy)
        end
      end
      fg = @ent.add_group face
      (tr = Geom::Transformation.new(cpt.vector_to(@cor)); tge.transform_entities(tr, tge.to_a)) if @spt == "Corner"
      @egrp = @ent.add_group
      @ege = @egrp.entities
      @egt = @egrp.transformation
      Sketchup::set_status_text "Intersecting Grid and Face"
      tge.intersect_with true, tgt, @ege, @egt, false, fg
      fg.explode
      tg.erase! unless $sdm_debug
    end

    def hopscotch2(face, dx, dy)
      hx = dx / 2.0
      hy = dy / 2.0
      p0 = Geom::Point3d.new()
      cpd = @mod.definitions
      cid = "HS2-#{dx.to_l}x#{dy.to_l}"
      cmp = cpd[cid]
      unless cmp
        cmp = cpd.add(cid)
        xa = [1, 0, 0]
        ya = [0, 1, 0]
        za = [0, 0, 1]
        p1 = p0.offset(ya, dy)
        cmp.entities.add_face(self.makeaface(p0, p1, za))
        p2 = p1.offset(xa, dx)
        cmp.entities.add_face(self.makeaface(p1, p2, za))
        p3 = p2.offset(xa, hx)
        cmp.entities.add_face(self.makeaface(p2, p3, za))
        p4 = p3.offset(ya, -hy)
        cmp.entities.add_face(self.makeaface(p3, p4, za))
        p5 = p4.offset(ya, -hy)
        cmp.entities.add_face(self.makeaface(p4, p5, za))
        p6 = p0.offset(xa, dx)
        p7 = p6.offset(ya, hy)
        cmp.entities.add_face(self.makeaface(p5, p0, za))
        cmp.entities.add_face(self.makeaface(p6, p2, za))
        cmp.entities.add_face(self.makeaface(p7, p4, za))
        ci = @ent.add_instance(cmp, p0)
        ci.erase!
      end
      delx = dx + hx
      diag = face.bounds.diagonal * 1.2
      ctr = face.bounds.center
      nx = (diag / delx).ceil
      ny = (diag / dy).ceil
      pt0 = ctr.offset(@v1, -(delx * (nx / 2 + 1))).offset(@v2, -(dy * (ny / 2 + 1)))
      tg = @ent.add_group
      tge = tg.entities
      tgt = tg.transformation
      cnt = 0
      max = nx * ny
      md = 1e9
      p0 = pt0.clone
      for i in 0..ny
        p0 = pt0.offset(@v2, dy * i)
        p0.offset!(@v1, -hx) if i % 2 == 1
        for j in 0..nx
          cnt += 1
          self.progress_bar(cnt, max, "No Name Grid")
          tge.add_instance(cmp, Geom::Transformation.axes(p0, @v1, @v2, @norm))
          (d = @cor.distance(p0); (cpt = p0.clone; md = d) if md > d) if @spt == "Corner" && j > 0
          p0.offset!(@v1, delx)
        end
      end
      fg = @ent.add_group face
      (tr = Geom::Transformation.new(cpt.vector_to(@cor)); tge.transform_entities(tr, tge.to_a)) if @spt == "Corner"
      @egrp = @ent.add_group
      @ege = @egrp.entities
      @egt = @egrp.transformation
      Sketchup::set_status_text "Intersecting Grid and Face"
      tge.intersect_with true, tgt, @ege, @egt, false, fg
      fg.explode
      tg.erase! unless $sdm_debug
    end

    def hopscotch3(face)
      cid = "HS3-#{@GX}X#{@GY}"
      cmp = @mod.definitions[cid]
      unless cmp
        cmp = @mod.definitions.add(cid)
        cde = cmp.entities
        norm = [0, 0, 1]
        p0 = [0.0, 0.0, 0.0]
        p1 = [8.0, 0.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [0.0, 24.0, 0.0]
        p1 = [0.0, 16.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [4.0, 4.0, 0.0]
        p1 = [4.0, 8.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [4.0, 8.0, 0.0]
        p1 = [0.0, 8.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [4.0, 4.0, 0.0]
        p1 = [0.0, 4.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [8.0, 16.0, 0.0]
        p1 = [12.0, 16.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [16.0, 20.0, 0.0]
        p1 = [16.0, 16.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [8.0, 24.0, 0.0]
        p1 = [8.0, 20.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [16.0, 8.0, 0.0]
        p1 = [20.0, 8.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [16.0, 24.0, 0.0]
        p1 = [16.0, 20.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [20.0, 8.0, 0.0]
        p1 = [20.0, 4.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [16.0, 8.0, 0.0]
        p1 = [16.0, 4.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [20.0, 0.0, 0.0]
        p1 = [24.0, 0.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [12.0, 12.0, 0.0]
        p1 = [16.0, 12.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [8.0, 16.0, 0.0]
        p1 = [4.0, 16.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [20.0, 8.0, 0.0]
        p1 = [24.0, 8.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [0.0, 16.0, 0.0]
        p1 = [0.0, 8.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [12.0, 4.0, 0.0]
        p1 = [12.0, 8.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [16.0, 16.0, 0.0]
        p1 = [16.0, 12.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [16.0, 12.0, 0.0]
        p1 = [16.0, 8.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [12.0, 12.0, 0.0]
        p1 = [12.0, 16.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [16.0, 20.0, 0.0]
        p1 = [24.0, 20.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [12.0, 8.0, 0.0]
        p1 = [12.0, 12.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [16.0, 4.0, 0.0]
        p1 = [12.0, 4.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [16.0, 4.0, 0.0]
        p1 = [20.0, 4.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [12.0, 0.0, 0.0]
        p1 = [20.0, 0.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [8.0, 20.0, 0.0]
        p1 = [4.0, 20.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [0.0, 8.0, 0.0]
        p1 = [0.0, 4.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [20.0, 4.0, 0.0]
        p1 = [20.0, 0.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [12.0, 16.0, 0.0]
        p1 = [16.0, 16.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [12.0, 4.0, 0.0]
        p1 = [12.0, 0.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [12.0, 8.0, 0.0]
        p1 = [8.0, 8.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [8.0, 20.0, 0.0]
        p1 = [8.0, 16.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [8.0, 0.0, 0.0]
        p1 = [12.0, 0.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [8.0, 4.0, 0.0]
        p1 = [8.0, 0.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [8.0, 8.0, 0.0]
        p1 = [4.0, 8.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [0.0, 4.0, 0.0]
        p1 = [0.0, 0.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [8.0, 4.0, 0.0]
        p1 = [4.0, 4.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [8.0, 4.0, 0.0]
        p1 = [8.0, 8.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [4.0, 16.0, 0.0]
        p1 = [0.0, 16.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [4.0, 20.0, 0.0]
        p1 = [4.0, 16.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        p0 = [4.0, 20.0, 0.0]
        p1 = [4.0, 24.0, 0.0]
        cde.add_face(self.makeaface(p0, p1, norm))
        unless @GX == 24.0 && @GY == 24.0
          xscl = @GX / 24.0
          yscl = @GY / 24.0
          zscl = 1.0
          trs = Geom::Transformation.scaling(xscl, yscl, zscl)
          cde.transform_entities(trs, cde.to_a)
        end
      end
      dx = @GX
      dy = @GY
      diag = face.bounds.diagonal * 1.2
      ctr = face.bounds.center
      nx = [(diag / dx).ceil, 5].max
      ny = [(diag / dy).ceil, 5].max
      org = ctr.offset(@v1, -(dx * (nx / 2))).offset(@v2, -(dy * (ny / 2)))
      tg = @ent.add_group
      tge = tg.entities
      tgt = tg.transformation
      cnt = 0
      max = nx * ny
      md = 1e9
      for i in 0...ny
        pt = org.offset(@v2, dy * i)
        for j in 0...nx
          cnt += 1
          self.progress_bar(cnt, max, "Irregular Polygon Grid")
          (d = @cor.distance(pt); (cpt = pt.clone; md = d) if md > d) if @spt == "Corner" && j > 0
          ci = tge.add_instance(cmp, Geom::Transformation.axes(pt, @v1, @v2, @norm))
          pt.offset!(@v1, dx)
        end
      end
      fg = @ent.add_group face
      (tr = Geom::Transformation.new(cpt.vector_to(@cor)); tge.transform_entities(tr, tge.to_a)) if @spt == "Corner"
      @egrp = @ent.add_group
      @ege = @egrp.entities
      @egt = @egrp.transformation
      Sketchup::set_status_text "Intersecting Grid and Face"
      tge.intersect_with true, tgt, @ege, @egt, false, fg
      fg.explode
      tg.erase! unless $sdm_debug
    end

    def hopscotch4(face, dx, dy)
      cid = "HS4-#{@GX}x#{@GY}"
      cmp = @mod.definitions[cid]
      unless cmp
        cmp = @mod.definitions.add(cid)
        cde = cmp.entities
        hx = dx / 2
        hy = dy / 2
        vx = Geom::Vector3d.new(1, 0, 0)
        vy = Geom::Vector3d.new(0, 1, 0)
        vz = Geom::Vector3d.new(0, 0, 1)
        p0 = Geom::Point3d.new(-hx, 0, 0)
        p1 = p0.offset(vx, hx)
        cde.add_face(self.makeaface(p0, p1, vz))
        p2 = p1.offset(vx, dx)
        cde.add_face(self.makeaface(p1, p2, vz))
        p3 = p2.offset(vx, dx)
        cde.add_face(self.makeaface(p2, p3, vz))
        p4 = p3.offset(vy, -hy)
        cde.add_face(self.makeaface(p3, p4, vz))
        p5 = p1.offset(vy, hy)
        cde.add_face(self.makeaface(p1, p5, vz))
        p6 = p5.offset(vx, -hx)
        cde.add_face(self.makeaface(p5, p6, vz))
        p7 = p5.offset(vy, hy)
        cde.add_face(self.makeaface(p5, p7, vz))
        p8 = p2.offset(vy, hy)
        cde.add_face(self.makeaface(p2, p8, vz))
        p9 = p8.offset(vy, hy)
        cde.add_face(self.makeaface(p8, p9, vz))
        p10 = p8.offset(vx, dx)
        cde.add_face(self.makeaface(p8, p10, vz))
        cde.add_face(self.makeaface(p10, p3, vz))
        p11 = p10.offset(vx, dx)
        cde.add_face(self.makeaface(p10, p11, vz))
        p12 = p11.offset(vy, -dy)
        cde.add_face(self.makeaface(p11, p12, vz))
      end
      diag = face.bounds.diagonal * 1.2
      ctr = face.bounds.center
      dxx = dx * 3 + hx
      nx = [(diag / dxx).ceil, 5].max
      ny = [(diag / dy).ceil, 5].max
      org = ctr.offset(@v1, -(dxx * (nx / 2))).offset(@v2, -(dy * (ny / 2)))
      tg = @ent.add_group
      tge = tg.entities
      tgt = tg.transformation
      cnt = 0
      max = nx * ny
      md = 1e9
      p0 = org.clone
      for i in 1..ny
        for j in 0..nx
          cnt += 1
          self.progress_bar(cnt, max, "Irregular Polygon Grid")
          (d = @cor.distance(p0); (cpt = p0.clone; md = d) if md > d) if @spt == "Corner" && j > 0
          tge.add_instance(cmp, Geom::Transformation.axes(p0, @v1, @v2, @norm))
          p0.offset!(@v1, dxx)
        end
        p0 = org.offset(@v2, dy * i).offset(@v1, -hx * (i % 7))
      end
      fg = @ent.add_group face
      (tr = Geom::Transformation.new(cpt.vector_to(@cor)); tge.transform_entities(tr, tge.to_a)) if @spt == "Corner"
      @egrp = @ent.add_group
      @ege = @egrp.entities
      @egt = @egrp.transformation
      Sketchup::set_status_text "Intersecting Grid and Face"
      tge.intersect_with true, tgt, @ege, @egt, false, fg
      fg.explode
      tg.erase! unless $sdm_debug
    end

    def hexagon(face, side)
      cpd = @mod.definitions
      ang = 30.0.degrees
      rad = side + @HW / Math.cos(ang)
      cid = "Hex-#{side.to_l}"
      cmp = cpd[cid]
      unless cmp
        org = [0, -rad, 0]
        xa = [1, 0, 0]
        ya = [0, 1, 0]
        za = [0, 0, 1]
        cmp = cpd.add(cid)
        ctb = rad * Math.cos(ang)
        vec = [0, -rad, 0]
        hex = @ent.add_ngon org, za, rad, 6
        pts = hex.each.collect { |e| e.end.position }
        tr1 = Geom::Transformation.rotation(org, za, ang)
        pts.each { |p| p.transform! tr1 }
        for i in 0...pts.length
          cmp.entities.add_face(self.makeaface(pts[i-1], pts[i], za))
        end
        hex.each { |e| @ent.erase_entities(e) }
      end
      cos = Math.cos(ang)
      ctb = rad * cos
      c2c = ctb * 2.0
      r2r = c2c * cos
      xo1 = ctb
      xo2 = ctb * 2.0
      yo1 = rad
      ctr = face.bounds.center
      diag = face.bounds.diagonal * 1.2
      nx = (diag / c2c).ceil
      ny = (diag / r2r).ceil
      pt0 = ctr.offset(@v1, -(c2c * (nx / 2))).offset(@v2, -(r2r * (ny / 2)))
      tg = @ent.add_group
      tge = tg.entities
      tgt = tg.transformation
      cnt = 0
      max = nx * ny
      md = 1e9
      for j in 0..ny
        if j % 2 == 1
          p0 = pt0.offset(@v1, xo1).offset(@v2, yo1)
        else
          p0 = pt0.offset(@v1, xo2).offset(@v2, yo1)
        end
        tge.add_instance(cmp, Geom::Transformation.axes(p0, @v1, @v2, @norm))
        for i in 0..nx
          cnt += 1
          self.progress_bar(cnt, max, "Hexagon Grid")
          tge.add_instance(cmp, Geom::Transformation.axes(p0, @v1, @v2, @norm))
          (d = @cor.distance(p0); (cpt = p0.clone; md = d) if md > d) if @spt == "Corner" && j > 0
          p0.offset!(@v1, c2c)
        end
        pt0.offset!(@v2, r2r)
      end
      fg = @ent.add_group face
      (tr = Geom::Transformation.new(cpt.vector_to(@cor)); tge.transform_entities(tr, tge.to_a)) if @spt == "Corner"
      @egrp = @ent.add_group
      @ege = @egrp.entities
      @egt = @egrp.transformation
      Sketchup::set_status_text "Intersecting Grid and Face"
      tge.intersect_with true, tgt, @ege, @egt, false, fg
      fg.explode
      tg.erase! unless $sdm_debug
    end

    def diamonds(face, side)
      rad = side + @HW / Math.cos(30.degrees)
      cid = "Dia-#{side}"
      cmp = @mod.definitions[cid]
      unless cmp
        cmp = @mod.definitions.add(cid)
        p0 = [0, 0, 0]
        za = [0, 0, 1]
        hex = @ent.add_ngon(p0, za, rad, 6)
        pts = hex.each.collect { |e| e.start.position }
        for i in 0...pts.length
          cmp.entities.add_face(self.makeaface(pts[i-1], pts[i], za))
        end
        for i in 0...pts.length
          p1 = p0.offset(p0.vector_to(pts[i-1]), p0.distance(pts[i-1]) / 2)
          cmp.entities.add_face(self.makeaface(p0, p1, za))
          p2 = pts[i-1].offset(pts[i-1].vector_to(pts[i]), rad / 2.0)
          cmp.entities.add_face(self.makeaface(p1, p2, za))
          p3 = pts[i-2].offset(pts[i-2].vector_to(pts[i-1]), rad / 2.0)
          cmp.entities.add_face(self.makeaface(p1, p3, za))
        end
        hex.each { |e| @ent.erase_entities(e) }
      end
      ctb = rad * Math.cos(30.degrees)
      c2c = rad * 3.0
      r2r = ctb * 2.0
      ctr = face.bounds.center
      diag = face.bounds.diagonal * 1.2
      nx = (diag / c2c).ceil
      ny = (diag / r2r).ceil
      pt0 = ctr.offset(@v1, -(c2c * (nx / 2))).offset(@v2, -(r2r * (ny / 2)))
      tg = @ent.add_group
      tge = tg.entities
      tgt = tg.transformation
      cnt = 0
      max = nx * ny
      md = 1e9
      p0 = pt0.clone
      for j in 0..ny
        for i in 0..nx
          cnt += 1
          self.progress_bar(cnt, max, "Hexagon Grid")
          tge.add_instance(cmp, Geom::Transformation.axes(p0, @v1, @v2, @norm))
          (d = @cor.distance(p0); (cpt = p0.clone; md = d) if md > d) if @spt == "Corner" && j > 0
          p1 = p0.offset(@v1, c2c / 2.0).offset(@v2, -ctb)
          tge.add_instance(cmp, Geom::Transformation.axes(p1, @v1, @v2, @norm))
          (d = @cor.distance(p1); (cpt = p1.clone; md = d) if md > d) if @spt == "Corner" && j > 0
          p0.offset!(@v1, c2c)
        end
        pt0.offset!(@v2, r2r)
        p0 = pt0.clone
      end
      fg = @ent.add_group face
      (tr = Geom::Transformation.new(cpt.vector_to(@cor)); tge.transform_entities(tr, tge.to_a)) if @spt == "Corner"
      @egrp = @ent.add_group
      @ege = @egrp.entities
      @egt = @egrp.transformation
      Sketchup::set_status_text "Intersecting Grid and Face"
      tge.intersect_with true, tgt, @ege, @egt, false, fg
      fg.explode
      tg.erase! unless $sdm_debug
    end

    def octagon(face, side)
      half = side / 2.0
      ang = 22.5.degrees
      rad = half / Math.sin(ang)
      rad += @HW / Math.cos(ang)
      @d_area = (side + (Math.tan(ang) * @HW) * 2) ** 2
      cpd = @mod.definitions
      cid = "Oct-#{side.to_l}"
      cmp = cpd[cid]
      unless cmp
        org = [@GW - half, @GW - half, 0]
        xa = [1, 0, 0]
        ya = [0, 1, 0]
        za = [0, 0, 1]
        cmp = cpd.add(cid)
        hex = @ent.add_ngon org, za, rad, 8
        pts = hex.each.collect { |e| e.end.position }
        tr1 = Geom::Transformation.rotation(org, za, ang)
        pts.each { |p| p.transform! tr1 }
        for i in 0...pts.length
          cmp.entities.add_face(self.makeaface(pts[i-1], pts[i], za))
        end
        hex.each { |e| @ent.erase_entities(e) }
      end
      ctb = half / Math.tan(ang)
      r2r = c2c = ctb * 2.0 + @GW
      ctr = face.bounds.center
      diag = face.bounds.diagonal * 1.2
      nx = (diag / c2c).ceil
      ny = (diag / r2r).ceil
      pt0 = ctr.offset(@v1, -(c2c * (nx / 2))).offset(@v2, -(r2r * (ny / 2)))
      tg = @ent.add_group
      tge = tg.entities
      tgt = tg.transformation
      p0 = pt0.clone
      cnt = 0
      max = nx * ny
      md = 1e9
      for j in 0..ny
        for i in 0..nx
          cnt += 1
          self.progress_bar(cnt, max, "Hexagon Grid")
          tge.add_instance(cmp, Geom::Transformation.axes(p0, @v1, @v2, @norm))
          (d = @cor.distance(p0); (cpt = p0.clone; md = d) if md > d) if @spt == "Corner" && j > 0
          p0.offset!(@v1, c2c)
        end
        p0 = pt0.offset(@v2, r2r)
        pt0.offset!(@v2, r2r)
      end
      fg = @ent.add_group face
      (tr = Geom::Transformation.new(cpt.vector_to(@cor)); tge.transform_entities(tr, tge.to_a)) if @spt == "Corner"
      @egrp = @ent.add_group
      @ege = @egrp.entities
      @egt = @egrp.transformation
      Sketchup::set_status_text "Intersecting Grid and Face"
      tge.intersect_with true, tgt, @ege, @egt, false, fg
      fg.explode
      tg.erase! unless $sdm_debug
    end

    def irregular_polygons(face)
      require File.dirname(__FILE__) + '/delauney3.rb'
      require File.dirname(__FILE__) + '/VoronoiXYZ.rb'
      ctr = face.bounds.center
      diag = face.bounds.diagonal * 1.2
      org = ctr.offset(@v1, -diag / 2).offset(@v2, -diag / 2)
      @sel.clear
      max = (face.area * @ipd / 144).floor
      nrm = face.normal
      @rds > 0 ? srand(@rds) : srand
      pts = []
      while max > 0
        x = diag * rand
        y = diag * rand
        p = org.offset(@v1, x).offset(@v2, y)
        if face.classify_point(p) == 1
          if self.proximity(pts, p) > 6.inch
            @sel.add @ent.add_cpoint(p)
            max -= 1
            pts << p
          end
        end
      end
      face.vertices.each { |v| @sel.add @ent.add_cpoint(v.position) }
      vgrp = MattC::VoronoiXYZ.voronoi()
      vgt = vgrp.transformation
      fgrp = @ent.add_group face
      cgrp = @ent.add_group
      cge = cgrp.entities
      cgt = cgrp.transformation
      vgrp.entities.grep(Sketchup::Edge).each { |e|
        p1 = e.start.position.transform vgt
        p2 = e.end.position.transform vgt
        cge.add_edge(p1, p2)
      }
      @egrp = @ent.add_group
      @ege = @egrp.entities
      @egt = @egrp.transformation
      cge.intersect_with true, cgt, @ege, @egt, false, fgrp
      vgrp.erase!
      cgrp.erase!
      fgrp.explode
      @ent.erase_entities(@sel)
    end

    def proximity(old, new)
      prox = 1e6
      for o in old
        prox = [o.distance(new), prox].min
        break if prox < 6.inch
      end
      return prox
    end

    def wedge(face, dx, dy)
      cid = "Wedge-#{dx.to_l}x#{dy.to_l}"
      cmp = @mod.definitions[cid]
      unless cmp
        cmp = @mod.definitions.add(cid)
        cde = cmp.entities
        p0 = Geom::Point3d.new()
        v1 = [1, 0, 0]
        v2 = [0, 1, 0]
        norm = [0, 0, 1]
        p1 = p0.offset(v1, -dx / 2).offset(v2, dy / 4)
        cde.add_face(self.makeaface(p0, p1, norm))
        p2 = p1.offset(v2, dy / 2)
        cde.add_face(self.makeaface(p1, p2, norm))
        p3 = p2.offset(v2, dy / 4).offset(v1, dx / 2)
        cde.add_face(self.makeaface(p2, p3, norm))
        p4 = p3.offset(v1, dx / 2).offset(v2, -dy / 4)
        cde.add_face(self.makeaface(p3, p4, norm))
        p5 = p4.offset(v2, -dy / 2)
        cde.add_face(self.makeaface(p4, p5, norm))
        cde.add_face(self.makeaface(p5, p0, norm))
      end
      diag = face.bounds.diagonal * 1.2
      ctr = face.bounds.center
      nx = [(diag / dx).ceil, 5].max
      ny = [(diag / dy).ceil, 5].max
      org = ctr.offset(@v1, -(dx * (nx / 2))).offset(@v2, -(dy * (ny / 2)))
      tg = @ent.add_group
      tge = tg.entities
      tgt = tg.transformation
      cnt = 0
      max = nx * ny
      md = 1e9
      p0 = org.clone
      for i in 0..ny
        pt = p0.offset(@v2, dy * 0.75 * i)
        pt.offset!(@v1, dx / 2) if i % 2 == 1
        for j in 0..nx
          cnt += 1
          self.progress_bar(cnt, max, "Wedge Grid")
          (d = @cor.distance(pt); (cpt = pt.clone; md = d) if md > d) if @spt == "Corner" && j > 0
          tge.add_instance(cmp, Geom::Transformation.axes(pt, @v1, @v2, @norm))
          pt.offset!(@v1, dx)
        end
      end
      fg = @ent.add_group face
      (tr = Geom::Transformation.new(cpt.vector_to(@cor)); tge.transform_entities(tr, tge.to_a)) if @spt == "Corner"
      @egrp = @ent.add_group
      @ege = @egrp.entities
      @egt = @egrp.transformation
      Sketchup::set_status_text "Intersecting Grid and Face"
      tge.intersect_with true, tgt, @ege, @egt, false, fg
      fg.explode
      tg.erase! unless $sdm_debug
    end

    def i_block(face, dx, dy)
      cid = "I_Block-#{@GX}x#{@GY}"
      cpd = @mod.definitions[cid]
      unless cpd
        cpd = @mod.definitions.add(cid)
        cde = cpd.entities
        p0 = [0, 0, 0]
        v1 = [-1, 0, 0]
        v2 = [0, 1, 0]
        v3 = [0, 0, 1]
        d1 = dx * 0.1875
        d2 = dx * 0.125
        d3 = dx - ((d1 + d2) * 2)
        dy = [dy, (d2 + @GW) * 2].max
        p1 = p0.offset(v1, d1)
        cde.add_face(self.makeaface(p0, p1, v3))
        p0 = p1
        p1 = p0.offset(v1, d2).offset(v2, d2)
        cde.add_face(self.makeaface(p0, p1, v3))
        p0 = p1
        p1 = p0.offset(v1, d3)
        cde.add_face(self.makeaface(p0, p1, v3))
        p0 = p1
        p1 = p0.offset(v1, d2).offset(v2, -d2)
        cde.add_face(self.makeaface(p0, p1, v3))
        p0 = p1
        p1 = p0.offset(v1, d1)
        cde.add_face(self.makeaface(p0, p1, v3))
        p0 = p1
        p1 = p0.offset(v2, dy)
        cde.add_face(self.makeaface(p0, p1, v3))
        p0 = p1
      end
      diag = face.bounds.diagonal * 1.2
      ctr = face.bounds.center
      nx = (diag / dx).ceil
      dy -= dx * 0.125
      ny = (diag / dy).ceil
      org = ctr.offset(@v1, -(dx * (nx / 2))).offset(@v2, -(dy * (ny / 2)))
      tg = @ent.add_group
      tge = tg.entities
      tgt = tg.transformation
      cnt = 0
      max = nx * ny
      md = 1e9
      for i in 0..ny
        p0 = org.offset(@v2, dy * i)
        p0.offset!(@v1, dx / 2.0) if i % 2 == 1
        for j in 0..nx
          cnt += 1
          self.progress_bar(cnt, max, "I_Block Grid")
          (d = @cor.distance(p0); (cpt = p0.clone; md = d) if md > d) if @spt == "Corner" && j > 0
          tge.add_instance(cpd, Geom::Transformation.axes(p0, @v1, @v2, @norm))
          p0.offset!(@v1, dx)
        end
      end
      fg = @ent.add_group face
      (tr = Geom::Transformation.new(cpt.vector_to(@cor)); tge.transform_entities(tr, tge.to_a)) if @spt == "Corner"
      @egrp = @ent.add_group
      @ege = @egrp.entities
      @egt = @egrp.transformation
      Sketchup::set_status_text "Intersecting Grid and Face"
      tge.intersect_with true, tgt, @ege, @egt, false, fg
      fg.explode
      tg.erase! unless $sdm_debug
    end

    def paint_it(f)
      if @app == "Current"
        f.material = @mat
        f.material.texture.size = @txs if f.material && f.material.texture && @txs && @txs != 0
        self.ate(f)
      elsif @app == "Rand_Clr"
        name = @colors[rand(@colors.length)]
        unless @mod.materials[name]
          mat = @mod.materials.add(name)
          mat.color = name
        end
        f.material = @mod.materials[name]
      elsif @app == "Rand_Tex"
        i = rand(@textures.length)
        name = @textures[i]
        f.material = @mod.materials[name]
        self.ate(f)
      end
    end

    def ate(f)
      if @ate == "Yes" && f.material && f.material.texture
        case @@opt
        when "Tweed", "BsktWv", "IrPoly"
          l = n = 0
          f.outer_loop.edges.each_with_index { |e, i| d = e.length; (n = i; l = d) if d > l }
          vector = f.edges[n].line[1]
        when "HpScth1", "HpScth2", "HpScth4"
          n = 0
          @GX >= @GY ? vector = @v1 : vector = @v2
        when 'HpScth3', "Hbone"
          edges = f.outer_loop.edges
          j = edges.length - 1
          l = d = 0
          for i in 0..j
            d += edges[i].length
            unless edges[i].line[1].parallel?(edges[i-j].line[1])
              (l = d; n = i; d = 0) if l < d
            end
          end
          vector = edges[n].line[1]
        else
          n = 0
          vector = @v1
        end
        return unless f.normal.perpendicular? vector
        achorPoint = f.edges[n].line[0]
        textureWidth = f.material.texture.width
        vector.length = textureWidth
        points = [achorPoint, [0, 0, 0], [achorPoint[0] + vector[0], achorPoint[1] + vector[1], achorPoint[2] + vector[2]], [1, 0, 0]]
        f.position_material(f.material, points, true)
      end
    end

    def wig(f)
      if f.material && f.material.texture
        tw = Sketchup.create_texture_writer
        uvh = f.get_UVHelper true, false, tw
        pointPairs = []
        vector = f.edges[0].line[1]
        vector.length = rand(f.material.texture.height + f.material.texture.width) * @rti
        trans = Geom::Transformation.rotation f.outer_loop.vertices[0].position, f.normal, rand(360).degrees
        vector.transform! trans
        trans = Geom::Transformation.translation vector
        (0..1).each do |j|
          point3d = f.outer_loop.vertices[j].position
          point3dRotated = point3d.transform(trans)
          pointPairs << point3dRotated
          point2d = uvh.get_front_UVQ(point3d)
          pointPairs << point2d
        end
        f.position_material(f.material, pointPairs, true)
      end
    end

    def wag(f)
      if f.material && f.material.texture
        tw = Sketchup.create_texture_writer
        uvh = f.get_UVHelper true, false, tw
        @rtr == "Rand" ? angle = rand(360) : (angle = @rtr.to_i; incs = 360 / angle; angle *= rand(incs))
        trans = Geom::Transformation.rotation f.outer_loop.vertices[0].position, f.normal, angle.degrees
        pointPairs = []
        (0..1).each do |j|
          point3d = f.outer_loop.vertices[j].position
          point3dRotated = point3d.transform(trans)
          pointPairs << point3dRotated
          point2d = uvh.get_front_UVQ(point3d)
          pointPairs << point2d
        end
        f.position_material(f.material, pointPairs, true)
      end
    end

    def wob(g, d)
      i = rand(2)
      axis = [@v1, @v2][i]
      while d < @rin || d > @rix
        d = rand * @GD
      end
      case @@opt
      when "Brick", "Tile", "Wood"
        angle = Math.atan(d / [@GY, @GX][i]) * (rand <=> 0.5)
      else
        angle = Math.atan(d / (([[g.bounds.height, g.bounds.depth].max, g.bounds.width].max) / 2)) * (rand <=> 0.5)
      end
      tr = Geom::Transformation.rotation(g.bounds.center, axis, angle)
      g.transform! tr
    end

	def bev(f, d)
		unless d.is_a?(Length)
		  d = d.to_l rescue 0.to_l
		  puts "Converted bevel size to Length: #{d}" if d > 0
		end
		return unless d > 0
	  
		if f && f.valid?
		  edges = f.edges
		  has_thickness = edges.any? { |e| e.faces.length > 1 }
		  if has_thickness
			p = self.g_offset(f, d)
			if p && p.length >= 3
			  begin
				b = f.parent.entities.add_face(p)
				if b && b.valid?
				  v = b.normal
				  v.length = d
				  tr = Geom::Transformation.translation(v)
				  f.parent.entities.transform_entities(tr, b)
				  puts "Bevel applied successfully"
				else
				  puts "Failed to create bevel face"
				end
			  rescue => e
				puts "Bevel failed: #{e.message}"
			  end
			else
			  puts "Failed to generate offset points for bevel"
			end
		  else
			puts "Cannot apply bevel: face has no thickness"
		  end
		else
		  puts "Cannot apply bevel: face is invalid"
		end
	  end

    def edge_to_close(f, p)
      return true if p[0].distance(p[1]) <= @GW
      for loop in f.loops
        loop.edges.each { |e|
          if e.line[1].parallel?(p[0].vector_to(p[1]))
            for i in 0..1
              pp = p[i].project_to_line(e.line)
              if e.bounds.contains?(pp)
                return true if p[i].distance(pp) <= @GW
              end
            end
          end
        }
      end
      return false
    end

	def g_offset(face, dist)
		return nil unless (dist.class == Integer || dist.class == Float || dist.class == Length)
		return nil if (@@opt != "I_Block" && !self.ctr_to_edge(face))
		@c_pts = face.outer_loop.vertices.collect { |v| v.position }
		unless dist == 0
		  edges = face.outer_loop.edges
		  last = edges.length - 1
		  0.upto(last) do |i|
			unless edges[i].length > @GW
			  if edges[i].line[1].perpendicular?(edges[i-1].line[1])
				if edges[i].line[1].perpendicular?(edges[i-last].line[1])
				  @c_pts -= [edges[i].start, edges[i].end]
				end
			  end
			end
		  end
		  last = @c_pts.length - 1
		  @o_pts = []
		  0.upto(last) do |a|
			vec1 = (@c_pts[a] - @c_pts[a-last]).normalize
			vec2 = (@c_pts[a] - @c_pts[a-1]).normalize
			if vec1.parallel? vec2
			  ctr = face.bounds.center
			  poe = ctr.project_to_line([@c_pts[a], vec1])
			  vec3 = poe.vector_to(ctr)
			  ang = 90.degrees
			else
			  vec3 = (vec1 + vec2).normalize
			  ang = vec1.angle_between(vec2) / 2
			end
			if vec3.valid?
			  vec3.length = -dist / Math::sin(ang)
			  t = Geom::Transformation.new(vec3)
			  if face.classify_point(@c_pts[a].transform(t)) == 16
				t = Geom::Transformation.new(vec3.reverse)
			  end
			  @o_pts << @c_pts[a].transform(t)
			end
		  end
		  (@o_pts.length > 2) ? (return @o_pts) : (return nil)
		else
		  return @c_pts # 如果 dist 為 0，直接返回原始點
		end
	  end

    def progress_bar(cnt, max, opt)
      pct = (cnt * 100) / max
      pct = [pct, 100].min
      @pb = "|" * pct
      Sketchup::set_status_text(@pb + " #{pct}% of #{opt} done.")
    end

    def makeaface(p1, p2, v)
      pts = []
      pts << p1.offset(v)
      pts << p2.offset(v)
      pts << p2.offset(v.reverse)
      pts << p1.offset(v.reverse)
      pts
    end

    def ctr_to_edge(f)
      edges = f.edges
      c = self.calc_centroid(f)
      edges.each { |e| return false if c.distance_to_line(e.line) <= @HW }
      return true
    end

	def calc_centroid(f)
		# 計算簡單平均質心
		tx = 0.0
		ty = 0.0
		tz = 0.0
		p = f.outer_loop.vertices.collect { |v| v.position }
		p.each { |v| tx += v.x; ty += v.y; tz += v.z }
		ax = tx / p.length
		ay = ty / p.length
		az = tz / p.length
		c = Geom::Point3d.new(ax, ay, az)
	  
		# 將質心投影到多邊形平面，確保平面一致性
		c = c.project_to_plane(f.plane) unless c.on_plane?(f.plane)
	  
		# 計算加權質心
		area = 0.0
		cx = 0.0
		cy = 0.0
		cz = 0.0
		for i in 0...p.length
		  # 計算底邊長度
		  base = p[i].distance(p[i-1])
		  # 如果底邊長度為 0，跳過此三角形
		  next if base == 0
	  
		  # 計算高度（質心到邊的距離）
		  vector = p[i].vector_to(p[i-1])
		  height = c.distance_to_line([p[i], vector])
	  
		  # 計算三角形面積
		  areat = (base * height) / 2.0
		  area += areat
	  
		  # 加權平均計算質心坐標
		  cx += areat * (p[i].x + p[i-1].x + c.x) / 3.0
		  cy += areat * (p[i].y + p[i-1].y + c.y) / 3.0
		  cz += areat * (p[i].z + p[i-1].z + c.z) / 3.0
		end
	  
		# 避免除以零的情況
		if area == 0
		  puts "Warning: Calculated area is zero, returning approximate centroid."
		  return c
		end
	  
		# 計算最終質心
		cx = cx / area
		cy = cy / area
		cz = cz / area
		Geom::Point3d.new(cx, cy, cz)
	  end
  end
end