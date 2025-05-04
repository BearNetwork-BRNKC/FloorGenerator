require File.dirname(__FILE__)+'delauney3.rb'

module MattC

	module VoronoiXYZ

		def self.voronoi()
			@mod = Sketchup.active_model
			@ent = @mod.active_entities
			@sel = @mod.selection
			###
			points_table = []
			points_table = self.points_to_array()
			###
			triangles = []
			if points_table[0]
				triangles = Delauney3::triangulate(points_table)
			else
				puts "No triangles were created."
				return nil
			end
			### group for tri's output
			point_groups=[]
			for i in 0..points_table.length-1
				point_groups[i]=[]
				triangles.each do |tri|
					if tri.include? i
						point_groups[i]<<tri
					end
				end
			end
			point_groups.each do |pg|
				pg.flatten!
				pg.uniq!
			end
			vgrp = @ent.add_group()
			grent=vgrp.entities
			conhull=[]
			qhull(@cpts).each do |p|
				for i in 0..points_table.length-1
					if p.position==points_table[i]
						conhull<<i
					end
				end
			end
			for i in 0..points_table.length-1
				connpoints=point_groups[i]
				if conhull.include?(i)
					j=conhull.index(i)
					if j == 0
						connpoints<<conhull[1]
						connpoints<<conhull[conhull.length-1]				
					else
						if j == conhull.length-1
							connpoints<<conhull[j-1]
							connpoints<<conhull[0]
						else
							connpoints<<conhull[j-1]
							connpoints<<conhull[j+1]
						end
					end
				end
				connpoints.uniq!
				connpoints.delete(i)
				sorted=sortradial(connpoints,i,points_table)
				cellpoints=voropoints(i,sorted,points_table,conhull)
				cellpoints=removedupilcates(cellpoints)
				if cellpoints.length>2
					grent.add_face(cellpoints)
				end
			end
			##### return everthing to original plane
			@ent.transform_entities(@trans.inverse,@cpts)
			vgrp.transform! @trans.inverse
			#####
		end#def
			
		def self.points_to_array()
			##### put selected ConstructionPoints on the XY plane
			@cpts = @sel.grep(Sketchup::ConstructionPoint)
			@bb = Geom::BoundingBox.new; @bb.add @cpts.map{|cp|cp.position};
			px,py,pz = plane = Geom.fit_plane_to_points(@cpts.map{|cp|cp.position})
			@cpts.each{|cp|
				pp = cp.position.project_to_plane(plane)
				vec = cp.position.vector_to(pp)
				@ent.transform_entities(Geom::Transformation.new(vec),cp)
			}
			x_axis = Geom::Vector3d.new(px,py,pz).axes[0]
			ang = Math.acos(pz); @max_length = @bb.diagonal/4
			@trans = Geom::Transformation.new(ORIGIN,x_axis,-ang)
			@ent.transform_entities(@trans,@cpts)
			#####
			points_array = []   
			@cpts.each{|cpt| ### TIG'd
				x = cpt.position.x.to_f
				y = cpt.position.y.to_f
				z = cpt.position.z.to_f
				points_array << [x, y ,z]
			}
			points_array.uniq!
			return points_array
		end #of def

		def self.removedupilcates(points)
			uniqpoints=[]; temp=[]
			n=points.length
			for i in 0..n-1
				for j in i+1..n-1
					if points[i]==points[j] || points[i].distance(points[j]) > @max_length
						temp<<points[j]
					end
				end
			end
			uniqpoints=points-temp
			uniqpoints
		end
		
		def self.qhull(points)
			vector=Geom::Vector3d.new 1,0,0 
			pminy=[points[0]]
			for i in 1..points.length-1
				if points[i].position.y < pminy.last.position.y
					pminy<<points[i]
				end
			end
			vertices=[pminy.last]
			temp=[]
			angle=180.degrees
			for i in 0..points.length-1
				if (vertices.last.position!=points[i].position)&&(vector.angle_between(vertices.last.position.vector_to(points[i].position)) < angle)
					temp<<points[i]
					angle = vector.angle_between(vertices.last.position.vector_to(points[i].position))
				end
			end
			vertices<<temp.last
			angle=180.degrees
			for k in 1..points.length-1
				vector=vertices[vertices.length-2].position.vector_to(vertices.last.position)
				for i in 0..points.length-1
					if (vertices.last.position!=points[i].position)&&(vector.angle_between(vertices.last.position.vector_to(points[i].position))<angle)
						temp<<points[i]
						angle = vector.angle_between(vertices.last.position.vector_to(points[i].position))
					end
				end
				vertices<<temp.last
				angle=vector.angle_between(vertices[vertices.length-2].position.vector_to(vertices.last.position))+180.degrees
				if vertices.first==vertices.last
					break
				end	
			end
			vertices.delete_at(vertices.length-1)
			vertices
		end
		
		def self.sortradial(pointsind,bpointindex,pointstable)
			angles=[]; sortedp=[]
			vec=Geom::Vector3d.new(1,0,0) 
			pointsind.each do |p|
				if vec.cross(pointstable[bpointindex].vector_to(pointstable[p])).z>=0
					angles<<vec.angle_between(pointstable[bpointindex].vector_to(pointstable[p]))
				else
					angles<<360.degrees-vec.angle_between(pointstable[bpointindex].vector_to(pointstable[p]))
				end
			end
			angles.sort!
			for i in 0..angles.length-1
				for j in 0..pointsind.length-1
					if vec.cross(pointstable[bpointindex].vector_to(pointstable[pointsind[j]])).z>=0
						if vec.angle_between(pointstable[bpointindex].vector_to(pointstable[pointsind[j]]))==angles[i]
							sortedp<<pointsind[j]
						break
						end
					else
						if 360.degrees-vec.angle_between(pointstable[bpointindex].vector_to(pointstable[pointsind[j]]))==angles[i]
							sortedp<<pointsind[j]
						break
						end
					end
				end
			end
			sortedp
		end

		def self.voropoints(bpntindx,sorpntindx,pointstable,conhulindx)
			polygon=[]
			conhulindx.each do |i|
				polygon<<pointstable[i]
			end
			points=[]
			vec=Geom::Vector3d.new(0,0,1) 
			for i in 0..sorpntindx.length-1
				if i<sorpntindx.length-1
					j=i+1
				else
					j=0
				end
				test=[]
				if (conhulindx.include? bpntindx)
					test<<0
				else
					test<<1
				end
				if (conhulindx.include? sorpntindx[i])
					test<<0
				else
					test<<1
				end
				if (conhulindx.include? sorpntindx[j])
					test<<0
				else	
					test<<1
				end
				linevector=[pointstable[bpntindx].vector_to(pointstable[sorpntindx[i]]),pointstable[bpntindx].vector_to(pointstable[sorpntindx[j]])]
				midpoints=[Geom.linear_combination(0.5,pointstable[bpntindx],0.5,pointstable[sorpntindx[i]]),Geom.linear_combination(0.5,pointstable[bpntindx],0.5,pointstable[sorpntindx[j]])]
				midlines=[[midpoints[0],vec.cross(linevector[0])],[midpoints[1],vec.cross(linevector[1])]]
				int=Geom.intersect_line_line([midlines[0][0],midlines[0][1]], [midlines[1][0],midlines[1][1]])
				if (test[0]==0)&&(test[1]==0)&&(test[2]==0)
					intprim=int+int.vector_to(pointstable[bpntindx])+int.vector_to(pointstable[bpntindx])
					points<<intprim.project_to_line([midlines[0][0],midlines[0][1]])
					points<<intprim
					points<<intprim.project_to_line([midlines[1][0],midlines[1][1]])
				else
					points<<int
				end
			end
			adjpoints=[]
			for i in 0..points.length-1
				if i==points.length-1
					j=0
				else
					j=i+1
				end
				if Geom.point_in_polygon_2D(points[i], polygon, true)
					adjpoints<<points[i]
					if Geom.point_in_polygon_2D(points[j], polygon, true)==false
						adjpoints<<Geom::Point3d.new(intersect_p_p_ps(points[i],points[j],polygon))
						if Geom.point_in_polygon_2D(pointstable[bpntindx], polygon, false)==false
							adjpoints<<Geom::Point3d.new(pointstable[bpntindx])
						end
					end
				else
					if Geom.point_in_polygon_2D(points[j], polygon, true)
						adjpoints<<Geom::Point3d.new(intersect_p_p_ps(points[i],points[j],polygon))
					end
				end
			end
			if adjpoints.length==0
				temp=intersections_ps_ps(points,polygon)
				if temp.length==2
					adjpoints<<Geom::Point3d.new(temp[0])
					adjpoints<<Geom::Point3d.new(temp[1])
					adjpoints<<Geom::Point3d.new(pointstable[bpntindx])
				end
			end
			adjpoints.reject! { |c| c.nil? }
			adjpoints
		end
		
		def self.intersect_p_p_ps(p1,p2,polygon)
			point=[]
			p1p2line=[p1,p1.vector_to(p2)]
			for i in 0..polygon.length-1
				if i==polygon.length-1
					j=0
				else
					j=i+1
				end
				ijline=[polygon[i],polygon[i].vector_to(polygon[j])]
				int=Geom.intersect_line_line(p1p2line, ijline)
				if (int)&&(point_is_between(p1,p2,int)&&point_is_between(polygon[i],polygon[j],int))
					point<<int
					break
				end
			end
			point[0]
		end
		
		def self.intersections_p_p_ps(p1,p2,polygon)
			point=[]
			p1p2line=[p1,p1.vector_to(p2)]
			for i in 0..polygon.length-1
				if i==polygon.length-1
					j=0
				else
					j=i+1
				end
				ijline=[polygon[i],polygon[i].vector_to(polygon[j])]
				int=Geom.intersect_line_line(p1p2line, ijline)
				if point_is_between(p1,p2,int)&&point_is_between(polygon[i],polygon[j],int)
					point<<int
				end
			end
			point
		end
		
		def self.intersections_ps_ps(points,polygon)
			point=[]
			for i in 0..polygon.length-1
				if i==polygon.length-1
					j=0
				else
					j=i+1
				end
				ijline=[polygon[i],polygon[i].vector_to(polygon[j])]
				for k in 0..points.length-1
					if k==points.length-1
						l=0
					else
						l=k+1
					end
					klline=[points[k],points[k].vector_to(points[l])]
					int=Geom.intersect_line_line(klline, ijline)
					if (int!=nil)&&(point_is_between(points[k],points[l],int))&&(point_is_between(polygon[i],polygon[j],int))
						point<<int
					end
				end
			end
			point.reject! { |c| c.nil? }
			point
		end
		
		def self.point_is_between(p1,p2,pt)
			bb=Geom::BoundingBox.new;bb.add p1,p2
			bb.contains?(pt)
		end	

	end#VoronoiXYZ
	
end

