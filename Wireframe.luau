const RunService = game:GetService("RunService")
type Wireframe = { Vector3 }
type Cleanup = ()->()
type WireframeMethods = {
	DefineCube: (n:number?)->(),
	Begin: (g:GuiObject,fov:number,offset:number)->Cleanup
}

const WireframeExport = {}
const Wireframe: Wireframe = table.create(8)

const function _RotatePitch(v:Vector3,tx:number):Vector3
	const sin,cos=math.sin(tx),math.cos(tx)
	return Vector3.new(v.X,cos*v.Y-sin*v.Z,sin*v.Y+cos*v.Z)
end

const function _RotateYaw(v:Vector3,ty:number):Vector3
	const sin,cos=math.sin(ty),math.cos(ty)
	return Vector3.new(cos*v.X+sin*v.Z,v.Y,sin*v.X+cos*v.Z)
end

const function _RotateRoll(v:Vector3,tz:number):Vector3
	const sin,cos=math.sin(tz),math.cos(tz)
	return Vector3.new(cos*v.X-sin*v.Y,v.Y*cos+v.X*sin,v.Z)
end

const function _FetchCenter(frame:GuiObject):Vector2
	const centerX=frame.AbsolutePosition.X+(frame.AbsoluteSize.X/2)
	const centerY=frame.AbsolutePosition.Y+(frame.AbsoluteSize.Y/2)
	return Vector2.new(centerX,centerY)
end

const function _Connect(p1:Vector2,p2:Vector2,ui:GuiObject,frame:Frame?):Frame
	const line=frame or Instance.new("Frame")
	const dx,dy=p2.X-p1.X,p2.Y-p1.Y
	const midX,midY=(p1.X+p2.X)/2,(p1.Y+p2.Y)/2
	const dist=math.sqrt(dx^2+dy^2)
	const angle=math.deg(math.atan2(dy,dx))

	line.AnchorPoint=Vector2.new(0.5, 0.5)
	line.Position=UDim2.fromOffset(midX, midY)
	line.Size=UDim2.fromOffset(dist,2)
	line.Rotation=angle
	line.Parent=ui
end

const function RotateAll(av:{Vector3},tx:number,ty:number,tz:number):{Vector3}
	const new=table.create(#av)
	
	for k,v in ipairs(av) do
		local rotated=_RotatePitch(v,tx)
		rotated=_RotateYaw(rotated,ty)
		rotated=_RotateRoll(rotated,tz)
		new[k]=rotated
	end
	
	return new
end

const function Project2D(av:{Vector3},fov:number,offset:number,screenCenter:Vector2):{Vector2}
	const new=table.create(#av) :: { Vector2 }
	const f=1/math.tan(fov/2)

	for k,v in av do
		const z=v.Z+offset
		if z<=0 then error(`scalar Z in vector of index {k} must be bigger than 0 to divide.`) end
		const nx=v.X*f/z
		const ny=v.Y*f/z
		new[k]=Vector2.new(nx+screenCenter.X,ny+screenCenter.Y)
	end

	return new
end

const function ConnectEdges(av:{Vector2},ui:GuiObject,existingFrames:{Frame}?):{Frame}
	const frames=existingFrames or table.create(12)
	const edges={
    {1, 2}, {2, 3}, {3, 4}, {4, 1},
    {5, 6}, {6, 7}, {7, 8}, {8, 5},
    {1, 5}, {2, 6}, {3, 7}, {4, 8}
	}
	for i,v in edges do 
		const connect,connect2=v[1],v[2]
		const edge,edge2=av[connect],av[connect2]
		if edge and edge2 then frames[i]=_Connect(edge,edge2,ui,frames[i]) end
	end
	return frames
end

function WireframeExport.DefineCube(n:number?)
	n=n/2 or 1
	Wireframe[1]=Vector3.new(-n,-n,n)
	Wireframe[2]=Vector3.new(n,-n,n)
	Wireframe[3]=Vector3.new(n,n,n)
	Wireframe[4]=Vector3.new(-n,n,n)
	Wireframe[5]=Vector3.new(-n,-n,-n)
	Wireframe[6]=Vector3.new(n,-n,-n)
	Wireframe[7]=Vector3.new(n,n,-n)
	Wireframe[8]=Vector3.new(-n,n,-n)
end

function WireframeExport.Begin(ui:GuiObject,fov:number,offset:number):Cleanup
	if #Wireframe==0 then error("use WireframeExport.DefineCube to define the vertices of your wireframe.") end
	local tx,ty,tz=0,0,0
	local frames:{Frame}
	const screenCenter=_FetchCenter(ui)
	const connection = RunService.RenderStepped:Connect(function(dt:number)
		const rotated=RotateAll(Wireframe,tx,ty,tz) 
		const projected=Project2D(rotated,fov,offset,screenCenter)
		frames=ConnectEdges(projected,ui,frames)
	end)

	return function()
		connection:Disconnect()
		for i,v in frames do v:Destroy() end;
		table.clear(frames)
		table.clear(Wireframe)
	end
end

return WireframeExport
