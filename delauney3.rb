class Delauney3

	def Delauney3::incircum(xp, yp, x1, y1, x2, y2, x3, y3)

		eps = 0.000001
		res = [FALSE, FALSE]

		if (y1 - y2).abs >= eps || (y2 - y3).abs >= eps
			if (y2 - y1).abs < eps
				m2 = -(x3 - x2) / (y3 - y2)
				mx2 = (x2 + x3) / 2
				my2 = (y2 + y3) / 2
				xc = (x1 + x2) / 2
				yc = m2 * (xc - mx2) + my2
			elsif (y3 - y2).abs < eps
				m1 = -(x2 - x1) / (y2 - y1)
				mx1 = (x1 + x2) / 2
				my1 = (y1 + y2) / 2
				xc = (x2 + x3) / 2
				yc = m1 * (xc - mx1) + my1
			else
				m1 = -(x2 - x1) / (y2 - y1)
				m2 = -(x3 - x2) / (y3 - y2)
				mx1 = (x1 + x2) / 2
				mx2 = (x2 + x3) / 2
				my1 = (y1 + y2) / 2
				my2 = (y2 + y3) / 2
				if (m1 - m2) == 0
					xc = (x1 + x2 + x3) / 3
					yc = (y1 + y2 + y3) / 3
				else
					xc = (m1 * mx1 - m2 * mx2 + my2 - my1) / (m1 - m2)
					yc = m1 * (xc - mx1) + my1
				end
			end

			dx = x2 - xc
			dy = y2 - yc
			rsqr = dx * dx + dy * dy
			r = Math.sqrt(rsqr)

			dx = xp - xc
			dy = yp - yc
			drsqr = dx * dx + dy * dy
			if drsqr < rsqr
				res[0] = TRUE
			end
			
			if xc + r < xp
				res[1] = TRUE
			end

		end

		return res

	end

	def Delauney3::triangulate(vert)

		vert.sort!
		
		nvert = vert.length

		triang = Array.new
		edges = Array.new
		complete = Array.new

		Sketchup.set_status_text("Starting triangulation of " + nvert.to_s + " Points")

		xmin = vert[0][0]
		ymin = vert[0][1]
		xmax = xmin
		ymax = ymin

		for i in (2..nvert)
			x1 = vert[i - 1][0]
			y1 = vert[i - 1][1]
			xmin = [x1, xmin].min
			xmax = [x1, xmax].max
			ymin = [y1, ymin].min
			ymax = [y1, ymax].max
		end

		dx = xmax - xmin
		dy = ymax - ymin
		dmax = [dx, dy].max
		xmid = (xmin + xmax) / 2
		ymid = (ymin + ymax) / 2

		p1 = nvert + 1
		p2 = nvert + 2
		p3 = nvert + 3
		vert[p1 - 1] = [xmid - 2 * dmax, ymid - dmax, 0]
		vert[p2 - 1] = [xmid, ymid + 2 * dmax, 0]
		vert[p3 - 1] = [xmid + 2 * dmax, ymid - dmax, 0]
		triang[0] = [p1 - 1, p2 - 1, p3 - 1]
		complete[0] = FALSE
		ntri = 1


		for i in (1..nvert)
			xp = vert[i - 1][0]
			yp = vert[i - 1][1]
			nedge = 0
			
  
		Sketchup.set_status_text("Triangulating point " + i.to_s + " / " + nvert.to_s )
		
			j = 0
			while j < ntri
				j = j +1
				if complete[j - 1] != TRUE
					p1 = triang[j - 1][0]
					p2 = triang[j - 1][1]
					p3 = triang[j - 1][2]
					x1 = vert[p1][0]
					y1 = vert[p1][1]
					x2 = vert[p2][0]
					y2 = vert[p2][1]
					x3 = vert[p3][0]
					y3 = vert[p3][1]
					inc = Delauney3::incircum(xp, yp, x1, y1, x2, y2, x3, y3)
					if inc[1] == TRUE
						complete[j - 1] = TRUE
					else
						if inc[0] == TRUE
							edges[nedge] = [p1, p2]
							edges[nedge + 1] = [p2, p3]
							edges[nedge + 2] = [p3, p1]
							nedge = nedge + 3
							triang[j - 1] = triang[ntri - 1]
							complete[j - 1] = complete[ntri - 1]
							j = j - 1
							ntri = ntri - 1
						end
					end
				end
			end

			for j in (1..nedge - 1)
				if edges[j - 1][0] != -1 || edges[j - 1][1] != -1
					for k in ((j + 1)..nedge)
						if edges[k - 1][0] != -1 || edges[k - 1][1] != -1
							if edges[j - 1][0] == edges[k - 1][1]
								if edges[j - 1][1] == edges[k - 1][0]
									edges[j - 1] = [-1, -1]
									edges[k - 1] = [-1, -1]
								end
							end
						end
					end
				end
			end

			for j in (1..nedge)
				if edges[j - 1][0] != -1 || edges[j - 1][1] != -1
					ntri = ntri + 1
					triang[ntri - 1] = [edges[j - 1][0], edges[j - 1][1], i - 1]
					complete[ntri - 1] = FALSE
				end
			end
		end

		i = 0
		while i < ntri
			i = i + 1
			if triang[i - 1][0] > nvert - 1 || triang[i - 1][1] > nvert - 1 || triang[i - 1][2] > nvert - 1
				triang[i - 1] = triang[ntri - 1]
				i = i - 1
				ntri = ntri - 1
			end
		end
		

	Sketchup.set_status_text("Triangulation Completed: "  + ntri.to_s + " Triangles Created.")

		return triang[0..ntri - 1]

	end

end
