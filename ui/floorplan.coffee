
$(document).on 'templateinit', (event) ->

  # define the item class
  class FloorplanItem extends pimatic.DeviceItem
    constructor: (templData, @device) ->
      super(templData, @device)

      @id = templData.deviceId
      @td = templData
      @floorplan = @device.config.floorplan

      @colorAttributeExtension = "_color"

      @floorplanDevices = {}
      for _dev, i in @device.config.devices
        @floorplanDevices[_dev.svgId] = @device.config.devices[i]
        #if _dev.format?.colorOff?
        #  @floorplanDevices[_dev.svgId]["colorOff"] = 'fill:' + _dev.format.colorOff
        #else
        #  @floorplanDevices[_dev.svgId]["colorOff"] = 'fill:#cccccc'


    getItemTemplate: => 'floorplan'

    afterRender: (elements) =>
      super(elements)
      ### Apply UI elements ###

      a = document.getElementById(@id)
      a.addEventListener("load",() =>
        svgDoc = a.contentDocument #get the inner DOM of alpha.svg
        @svgRoot = svgDoc.documentElement
       
        #$(@svgRoot).on("click", (e)=>
        #  @panZoom.zoomIn()
        #  #@panZoom.fit()
        #)
        $(@svgRoot).on("dblclick", (e)=>
          @panZoom.center()
          @panZoom.fit()
        )

        for i, _device of @floorplanDevices
          _id = _device.svgId
          attribute = @getAttribute(_id)
          if attribute?
            _tId = "#" + _id
            _selector = $(_tId, @svgRoot)
            # save the designed 'on' color
            _onColor = _selector.attr("style")
            try
              _format = JSON.parse(_device.format)
            catch err
              _format = {}
            @floorplanDevices[_id]["format"] = _format
            @floorplanDevices[_id]["colorOff"] = "fill:#cccccc;opacity:0.3" # _device.format?.colorOn ? _onColor
            @floorplanDevices[_id]["colorOn"] = _onColor # _device.format?.colorOn ? _onColor

            switch _device.type
              when 'switch'
                @_switchOnOff(_id,attribute.value())
                _selector.on("click", (e)=>
                  if @floorplanDevices[e.target.id].state
                    @_switchOnOff(e.target.id,false)
                    @_setState(e.target.id, false)
                  else
                    @_switchOnOff(e.target.id,true)
                    @_setState(e.target.id, true)
                )
                @_onRemoteStateChange _id

              when 'button'
                @_buttonOnOff(_id, false)
                _selector.on("click", (e)=>
                  @_buttonOnOff(e.target.id, true)
                  @_setButton(e.target.id)
                )
                @_onRemoteStateChange _id

              when 'light'
                attributeColor = @getAttribute(_id+@colorAttributeExtension)
                attributeState = @getAttribute(_id)
                @_lightOnOff(_id,attributeState.value())
                _selector.on("click", (e)=>
                  if @floorplanDevices[e.target.id].state
                    @_lightOnOff(e.target.id,false)
                    @_setLight(e.target.id,false)
                  else
                    @_lightOnOff(e.target.id,true)
                    @_setLight(e.target.id,true)
                )
                @_onRemoteStateChange _id
                @_onRemoteColorChange _id

              when 'presence'
                @_presenceOnOff(_id,attribute.value())
                @_onRemoteStateChange _id

              when 'contact'
                @_contactOnOff(_id,attribute.value())
                @_onRemoteStateChange _id

              when 'shutter'
                _tShutter = "#" + _id
                if $(_tShutter, @svgRoot)?
                  _isNumber = not Number.isNaN(attribute.value())
                  if _isNumber
                    @_createShutter(_id)
                    @_setShutter(_id, attribute.value())
                    @_onRemoteStateChange _id

              when 'sensor'
                _color = $(_tId, @svgRoot).css('fill')
                if _selector.text() isnt ""
                  #alert("text")
                  _selector.text(@_sensorFullValue(_id, attribute.value()))
                _selector.css('fill',_color)
                @_onRemoteStateChange _id

              when 'sensor_gauge'
                _tGauge = "#" + _id
                if $(_tGauge, @svgRoot)?
                  _isNumber = not Number.isNaN(attribute.value())
                  if _isNumber
                    @_createGauge(_id)
                    @_setGauge(_id, attribute.value())
                    @_onRemoteStateChange _id

              when 'clock'
                _tClock = "#" + _id
                if $(_tClock, @svgRoot)?
                  _isNumber = not Number.isNaN(attribute.value())
                  if _isNumber # number is type of clock
                    @_createClock(_id)
                    @_setClock(_id, attribute.value())
                    @_onRemoteStateChange _id

              when 'sensor_bar'
                _tBar = "#" + _id
                if $(_tBar, @svgRoot)?
                  _isNumber = not Number.isNaN(attribute.value())
                  if _isNumber
                    @_createBar(_id)
                    @_setBar(_id, attribute.value())
                    @_onRemoteStateChange _id

              when 'camera'
                @_createCamera(_id)
                @_createCameraLabel(_id)
                @_setCamera(_id,attribute.value())
                @_onRemoteStateChange _id

        @panZoom = svgPanZoom(@svgRoot, {dblClickZoomEnabled:false, preventMouseEventsDefault:false, zoomScaleSensitivity:0.3})

      )

    
    getCartesian: (cx, cy, radius, angle) =>
      rad = angle * Math.PI / 180
      return {
        x: Math.round((cx + radius * Math.cos(rad)) * 1000) / 1000
        y: Math.round((cy + radius * Math.sin(rad)) * 1000) / 1000
      }

    _dom2Svg: (_id, _x, _xP, _y, _yP) =>
      elem = @svgRoot.getElementById(_id)
      _dom = elem.getBoundingClientRect()

      #alert(JSON.stringify(_dom,null,2))
 
      pt = @svgRoot.createSVGPoint()
      pt["x"] = (_dom.x + _dom.width*_x + _xP)
      pt["y"] = (_dom.bottom + _dom.height*_y + _yP) #+_dom.height/2
      #alert(pt.x+' - '+pt.y)
      svgP = pt.matrixTransform(@svgRoot.getScreenCTM().inverse())
      pt["x"] = (_dom.x)
      pt["y"] = (_dom.y)
      svgP2 = pt.matrixTransform(@svgRoot.getScreenCTM().inverse())
      pt["x"] = (_dom.x+_dom.width)
      pt["y"] = (_dom.y+_dom.height)
      svgP3 = pt.matrixTransform(@svgRoot.getScreenCTM().inverse())

      return
        x: svgP.x
        y: svgP.y
        width: Number svgP3.x - Number svgP2.x
        height: Number svgP3.y - Number svgP2.y

    _createShutter: (_id) =>
      _xy = @_dom2Svg(_id, 0, 0.5, -1, 0)
      _x = Number _xy.x
      _y = Number _xy.y # - Number _xy.height
      _width = Number _xy.width
      _height = Number _xy.height
      _w = Math.round(_width)
      _h = Math.round(_height)

      @floorplanDevices[_id]["xy"] = _xy

      _rectStyle = @svgRoot.getElementById(_id)
      if _rectStyle?
        _style = _rectStyle.getAttribute('style')
        _rectStyle.remove()
      else
        _style = @floorplanDevices[_id].format?.fill ? 'fill:red'

      @floorplanDevices[_id]["style"] = _style
      _rect = document.createElementNS('http://www.w3.org/2000/svg', 'rect')

      _rect.setAttribute('id',_id)
      _rect.setAttribute('x',_x)
      _rect.setAttribute('y',_y)
      _rect.setAttribute('width',_w)
      _rect.setAttribute('height',_height)
      _rect.setAttribute('style',_style)
      @floorplanDevices[_id]["shutter"] = _rect
      @svgRoot.appendChild(_rect)

      _valueLabel = @_createText(_id, 0.5, -10, 0, 15, "black")
      _valueLabel.innerHTML = "20"

      @floorplanDevices[_id]["height"] = _xy.height
      @floorplanDevices[_id]["width"] = _xy.width
      @floorplanDevices[_id]["label"] = _valueLabel

      @svgRoot.appendChild(_valueLabel)

    _createBar: (_id) =>
      _xy = @_dom2Svg(_id, 0, 0.5, 0, 0)
      _x = Number _xy.x
      _y = Number _xy.y - Number _xy.height
      _width = Number _xy.width
      _height = Number _xy.height
      _w = Math.round(_width)
      _h = Math.round(_height)

      @floorplanDevices[_id]["xy"] = _xy

      _rectStyle = @svgRoot.getElementById(_id)
      if _rectStyle?
        _style = _rectStyle.getAttribute('style')
        _rectStyle.remove()
      else
        _style = @floorplanDevices[_id].format?.fill ? 'fill:red'

      @floorplanDevices[_id]["style"] = _style
      _rect = document.createElementNS('http://www.w3.org/2000/svg', 'rect')

      _rect.setAttribute('id',_id)
      _rect.setAttribute('x',_x)
      _rect.setAttribute('y',_y)
      _rect.setAttribute('width',_w)
      _rect.setAttribute('height',_height)
      _rect.setAttribute('style',_style)
      @floorplanDevices[_id]["bar"] = _rect
      @svgRoot.appendChild(_rect)

      _txtMin = @_createText(_id, 0, -15, 0, 0)
      _min = Number @floorplanDevices[_id].format?.min ? null
      _txtMin.innerHTML = _min if _min?

      _txtMax = @_createText(_id, 0, -15, -1, 0)
      _max = Number @floorplanDevices[_id].format?.max ? null
      _txtMax.innerHTML = _max if _max?

      _txtMid = @_createText(_id, 0, -15, -0.5, 0)
      _maxM = Number _max ? 100
      _minM = Number _min ? 0
      _txtMid.innerHTML = Math.round ((_minM + _maxM) / 2)

      _valueLabel = @_createText(_id, 0.5, -10, 0, 15, "black")
      _valueLabel.innerHTML = "20"

      @floorplanDevices[_id]["height"] = _xy.height
      @floorplanDevices[_id]["width"] = _xy.width
      @floorplanDevices[_id]["label"] = _valueLabel

      @svgRoot.appendChild(_valueLabel)
      @svgRoot.appendChild(_txtMin)
      @svgRoot.appendChild(_txtMid)
      @svgRoot.appendChild(_txtMax)

    _createGauge: (_id) =>
      _xy = @_dom2Svg(_id, 0.5, 0, 0, 0)
      _x = _xy.x
      _y = _xy.y
      _width = _xy.width
      _height = _xy.height
      @floorplanDevices[_id].xy = _xy 

      _line = document.createElementNS('http://www.w3.org/2000/svg', 'line')
      _line.setAttribute('x1',_x)
      _line.setAttribute('y1',_y)
      _line.setAttribute('x2',_x+_width)
      _line.setAttribute('y2',_y)
      _line.setAttribute('stroke',"red")

      _format = @floorplanDevices[_id].format if @floorplanDevices[_id].format?
      _radius = _format.radius ? (@floorplanDevices[_id]["radius"] ? _width/2)
      @floorplanDevices[_id]["value"] = @floorplanDevices[_id]["format"]["min"] ? 20
      coords = @getCartesian(_xy.x, _xy.y, _radius, 180)
      _line.setAttribute('x2',coords.x)
      _line.setAttribute('y2',coords.y)
      
      _animateTransform = document.createElementNS('http://www.w3.org/2000/svg','animateTransform')
      _animateTransform.setAttributeNS(null,'attributeName','transform')
      _animateTransform.setAttributeNS(null,"attributeType", "XML")
      _animateTransform.setAttributeNS(null,'type','rotate')
      _animateTransform.setAttributeNS(null,'dur','1s')
      _animateTransform.setAttributeNS(null,'repeatCount','1')
      _line.appendChild(_animateTransform)

      @floorplanDevices[_id]["gauge"] = _line
      @floorplanDevices[_id]["radius"] = _height
      @floorplanDevices[_id]["onColor"] = @svgRoot.getElementById(_id).getAttribute("fill")
      _dot = document.createElementNS('http://www.w3.org/2000/svg', 'circle')
      _dot.setAttribute('r',5)
      _dot.setAttribute('fill',"black")
      _dot.setAttribute('cx',_x)
      _dot.setAttribute('cy',_y)

      _txtMin = @_createText(_id, 0, -11, 0.05, 0 , "blue")
      _min = @floorplanDevices[_id].format?.min ? null
      _txtMin.innerHTML = _min if _min?

      _txtMax = @_createText(_id, 1, 1, 0.05, 0, "red")
      _max = @floorplanDevices[_id].format?.max ? null
      _txtMax.innerHTML = _max if _max?

      if _min? and _max?
        _txtMid = @_createText(_id, 0.5, -10, -1, 0, "green")
        _maxM = Number _max ? 100
        _minM = Number _min ? 0
        _txtMid.innerHTML = Math.round ((_minM + _maxM) / 2)
        @svgRoot.appendChild(_txtMin)
        @svgRoot.appendChild(_txtMax)
        @svgRoot.appendChild(_txtMid)

      _valueLabel = @_createText(_id, 0.5, -10, 0.05, 0, "white")
      _valueLabel.innerHTML = _min ? "0"
      @floorplanDevices[_id]["label"] = _valueLabel

      @svgRoot.appendChild(_line)
      @svgRoot.appendChild(_dot)
      @svgRoot.appendChild(_valueLabel)

    _createClock: (_id) =>
      _xy = @_dom2Svg(_id, 0.5, 0, -0.5, 0)
      _x = _xy.x
      _y = _xy.y
      _width = _xy.width
      _height = _xy.height
      @floorplanDevices[_id].xy = _xy 

      _format = @floorplanDevices[_id].format if @floorplanDevices[_id].format?
      _colorHour = _format.colorHour ? "blue"
      _colorMinute = _format.colorMinute ? "red"
      _colorSecond = _format.colorSecond ? "green"
      _strokeHour = _format.strokeHour ? 1
      _strokeMinute = _format.strokeMinute ? 1
      _strokeSecond = _format.strokeSecond ? 0.3
      _lengthHour = _format.lengthHour ? 0.6
      _lengthMinute = _format.lengthMinute ? 0.9
      _lengthSecond = _format.lengthSecond ? 1
      _dotSize = _format.dotSize ? 1
      _dotColor = _format.dotColor ? "gray"

      _hour = document.createElementNS('http://www.w3.org/2000/svg', 'line')
      _hour.setAttribute('x1',_x)
      _hour.setAttribute('y1',_y)
      _hour.setAttribute('x2',_x)
      _hour.setAttribute('y2',_y-(_height/2)*_lengthHour)
      _hour.setAttribute('stroke',_colorHour)
      _hour.setAttribute('stroke-width',_strokeHour)

      _minute = document.createElementNS('http://www.w3.org/2000/svg', 'line')
      _minute.setAttribute('x1',_x)
      _minute.setAttribute('y1',_y)
      _minute.setAttribute('x2',_x)
      _minute.setAttribute('y2',_y-(_height/2)*_lengthMinute)
      _minute.setAttribute('stroke',_colorMinute)
      _minute.setAttribute('stroke-width',_strokeMinute)

      _second = document.createElementNS('http://www.w3.org/2000/svg', 'line')
      _second.setAttribute('x1',_x)
      _second.setAttribute('y1',_y)
      _second.setAttribute('x2',_x)
      _second.setAttribute('y2',_y-(_height/2)*_lengthSecond)
      _second.setAttribute('stroke',_colorSecond)
      _second.setAttribute('stroke-width',_strokeSecond)

      @floorplanDevices[_id]["hour"] = _hour
      @floorplanDevices[_id]["minute"] = _minute
      @floorplanDevices[_id]["second"] = _second
      _dot = document.createElementNS('http://www.w3.org/2000/svg', 'circle')
      _dot.setAttribute('r', _dotSize)
      _dot.setAttribute('fill', _dotColor)
      _dot.setAttribute('cx',_x)
      _dot.setAttribute('cy',_y)

      if _format.label?
        _valueLabel = @_createText(_id, 0.5, 0, 0.05, 10, "black", @floorplanDevices[_id].name)
        @floorplanDevices[_id]["label"] = _valueLabel
        @svgRoot.appendChild(_valueLabel)

      @svgRoot.appendChild(_hour)
      @svgRoot.appendChild(_minute)
      @svgRoot.appendChild(_second)
      @svgRoot.appendChild(_dot)

      @_clockTick(_id)

    _createCamera: (_id) =>
      _format = @floorplanDevices[_id].format if @floorplanDevices[_id].format?
      _url = _format.camera
      if @floorplanDevices[_id]["xy"]?
        _xy = @floorplanDevices[_id]["xy"]
      else
        _xy = @_dom2Svg(_id, 0, 0, -1, 0)
        @floorplanDevices[_id]["xy"] = _xy

      _image = document.createElementNS('http://www.w3.org/2000/svg', 'image')
      _image.setAttributeNS(null,'x',_xy.x)
      _image.setAttributeNS(null,'y',_xy.y)
      _image.setAttributeNS(null,'width',_xy.width)
      _image.setAttributeNS(null,'height',_xy.height)
      _image.setAttributeNS('http://www.w3.org/1999/xlink','href', _url)

      @floorplanDevices[_id]["camera"] = _image
      @svgRoot.appendChild(_image)
      return _image

    _createCameraLabel: (_id) =>
      _valueLabel = @_createText(_id, 0.5, -20, 0.1, 0, "black")
      @floorplanDevices[_id]["label"] = _valueLabel
      _valueLabel.innerHTML = @floorplanDevices[_id].name ? _id
      @svgRoot.appendChild(_valueLabel)


    _createText: (_id, _x, _xP, _y, _yP, _color, _text) =>
      _xy = @_dom2Svg(_id, _x, _xP, _y, _yP)
      _x1 = _xy.x
      _y1 = _xy.y
      _txtLbl = document.createElementNS('http://www.w3.org/2000/svg', 'text')
      _txtLbl.setAttribute('id',_id+"_label")
      _txtLbl.style['font-family'] = 'sans-serif'
      _txtLbl.style['font-size'] = '3px'

      @svgRoot.appendChild(_txtLbl)
      if _text?
        _txtLbl.innerHTML = _text
        #alert($('#'+_id+"_label",@svgRoot).width())
        _delta = Number $('#'+_id+"_label",@svgRoot).width()/2
        #alert(_delta)
        _x1Center = _x1 - _delta
      else
        _x1Center = _x1
      _txtLbl.setAttribute('x',_x1Center)
      _txtLbl.setAttribute('y',_y1)
      _txtColor = if _color? then _color else "black"
      #_txtLbl.setAttribute('style','fill:'+_txtColor+';fontFamily:sans-serif;fontSize:3;')
      _txtLbl.style.fill = _txtColor

      return _txtLbl

    _setBar: (_id, value) =>
      _isNumber = not Number.isNaN(value)
      _format = @floorplanDevices[_id].format if @floorplanDevices[_id].format?
      _min = _format.min ? 0
      _max = _format.max ? 100
      _valFactor = Math.max((value-_min)/(_max-_min),0)
      _height = @floorplanDevices[_id]["height"]
      _xy = @floorplanDevices[_id].xy # @_dom2Svg(_id, 0, 0, 0, 0)
      _newY = _xy.y - _height * _valFactor
      _rect = @floorplanDevices[_id]["bar"]
      _rect.setAttribute('y',_newY)
      _rect.setAttribute('height', _height * _valFactor)
      _h = _height * _valFactor
      #alert('_xy.y:'+_xy.y+', y:'+_newY+', height:'+_h)
      _rect.setAttribute('style',@floorplanDevices[_id].style+";transition:all 1s;")

      @floorplanDevices[_id]['label'].innerHTML = @_sensorFullValue(_id,value)
 
    _setGauge: (_id, value) =>
      # value 0=180 -> 40=360
      _format = @floorplanDevices[_id].format if @floorplanDevices[_id].format?
      _min = _format.min ? 0
      _max = _format.max ? 100
      _curVal = ((Number @floorplanDevices[_id]["value"])-_min)*180/(_max-_min)
      _newVal = (value-_min)*180/(_max-_min)

      _xy = @floorplanDevices[_id].xy #_xy = @_dom2Svg(_id, 0.5, 0, 0, 0)
      _line = @floorplanDevices[_id]["gauge"]

      _animateTransform = _line.childNodes[0]
      _animateTransform.setAttributeNS(null,'from',_curVal+' '+_xy.x+' '+_xy.y)
      _animateTransform.setAttributeNS(null,'to',_newVal+' '+_xy.x+' '+_xy.y)
      _animateTransform.beginElement()

      _line.setAttribute('transform','rotate('+_newVal+' '+_xy.x+' '+_xy.y+')')
      @floorplanDevices[_id]["value"] = Number value

      @floorplanDevices[_id]['label'].innerHTML = @_sensorFullValue(_id,value)

    _setClock: (_id, value) =>
      return

    _clockTick: (_id) =>
      # value 0=360 -> 0-59 of 0-11/12-23
      _date = new Date()
      _newSecond =  _date.getSeconds()*6
      _newMinute = _date.getMinutes()*6 + 0.1*_date.getSeconds()
      _newHour =  _date.getHours()
      if _newHour > 11 then _newHour -=12
      _newHour = 30* _newHour + 0.5 * _date.getMinutes()

      _xy = @floorplanDevices[_id].xy
      _second = @floorplanDevices[_id]["second"]
      _minute = @floorplanDevices[_id]["minute"]
      _hour = @floorplanDevices[_id]["hour"]

      _second.setAttribute('transform','rotate('+_newSecond+' '+_xy.x+' '+_xy.y+')')
      _minute.setAttribute('transform','rotate('+_newMinute+' '+_xy.x+' '+_xy.y+')')
      _hour.setAttribute('transform','rotate('+_newHour+' '+_xy.x+' '+_xy.y+')')

      @floorplanDevices[_id]["clockTimer"] = setTimeout(=>
        @_clockTick(_id)
      , 1000)

    _setShutter: (_id, value) =>
      _isNumber = not Number.isNaN(value)
      _format = @floorplanDevices[_id].format if @floorplanDevices[_id].format?
      _min = 0
      _max = 100
      _valFactor = Math.max((value-_min)/(_max-_min),0)
      _height = @floorplanDevices[_id]["height"]
      _xy = @floorplanDevices[_id].xy # @_dom2Svg(_id, 0, 0, 0, 0)
      _newY = _xy.y # - _height * _valFactor
      _rect = @floorplanDevices[_id]["shutter"]
      _rect.setAttribute('y',_newY)
      _rect.setAttribute('height', _height * (1 - _valFactor))
      _h = _height * _valFactor
      _dur = 
      _rect.setAttribute('style',@floorplanDevices[_id].style+";transition:all 2s;")

      @floorplanDevices[_id]['label'].innerHTML = @_sensorFullValue(_id,value)

    _setCamera: (_id, value) =>

      return

      _camera = document.getElementById(_id)
      _label = @floorplanDevices[_id].name ? _id
      _url = @floorplanDevices[_id].format.camera

      if _camera?
        @svgRoot.removeChild(_camera)
      if Boolean value is true
        _camera = @_createCamera(_id)
        @svgRoot.appendChild(_camera)
        @floorplanDevices[_id]["label"].innerHTML = _label
        @floorplanDevices[_id].state = true
        if @panZoom?
          @panZoom.destroy()
        @panZoom = svgPanZoom(@svgRoot,{dblClickZoomEnabled:false})
      else
        @floorplanDevices[_id].camera = null
        @floorplanDevices[_id]["label"].innerHTML = _label + " - OFF"
        @floorplanDevices[_id].state = false


    _switchOnOff: (_id, onoff) =>
      _tId = "#" + _id
      @floorplanDevices[_id]["state"] = onoff
      if onoff
        _onColor = @floorplanDevices[_id]["colorOn"]
        $(_tId, @svgRoot).attr('style',_onColor)
      else
        _offColor = @floorplanDevices[_id]["colorOff"]
        $(_tId, @svgRoot).attr('style',_offColor)

    _presenceOnOff: (_id, onoff) =>
      _tId = "#" + _id
      @floorplanDevices[_id]["state"] = onoff
      if onoff
        _onColor = @floorplanDevices[_id]["colorOn"]
        $(_tId, @svgRoot).attr('style',_onColor)
      else
        _offColor = @floorplanDevices[_id]["colorOff"]
        $(_tId, @svgRoot).attr('style',_offColor)

    _contactOnOff: (_id, onoff) =>
      _tId = "#" + _id
      @floorplanDevices[_id]["state"] = onoff
      if onoff
        _onColor = @floorplanDevices[_id]["colorOn"]
        $(_tId, @svgRoot).attr('style',_onColor)
      else
        _offColor = @floorplanDevices[_id]["colorOff"]
        $(_tId, @svgRoot).attr('style',_offColor)

    _lightOnOff: (_id, onoff) =>
      _tId = "#" + _id
      @floorplanDevices[_id]["state"] = onoff
      if onoff
        _onColor = @floorplanDevices[_id]["colorOn"]
        $(_tId, @svgRoot).attr('style',_onColor)
      else
        _offColor = @floorplanDevices[_id]["colorOff"]
        $(_tId, @svgRoot).attr('style',_offColor)

    _cameraOnOff: (_id, onoff) =>
      _tId = "#" + _id
      @floorplanDevices[_id]["state"] = onoff
      if onoff
        _onColor = @floorplanDevices[_id]["colorOn"]
        #$(_tId, @svgRoot).attr('style',_onColor)
      else
        _offColor = @floorplanDevices[_id]["colorOff"]
        $(_tId, @svgRoot).attr('style',_offColor)

    _buttonOnOff: (_id, onoff) =>
      _tId = "#" + _id
      _offColor = @floorplanDevices[_id]["colorOff"]
      _onColor = @floorplanDevices[_id]["colorOn"]
      if onoff
        $(_tId, @svgRoot).clearQueue()
        $(_tId, @svgRoot).attr('style',_onColor)
        setTimeout( =>
          $(_tId, @svgRoot).attr('style',_offColor)
        , 1500)
      else
        $(_tId, @svgRoot).attr('style',_offColor)

    _sensorFullValue: (_id, value) =>
      _value = ''
      if @floorplanDevices[_id]['acronym']? then _value += (@floorplanDevices[_id]['acronym'] + " ")
      _value += value
      if @floorplanDevices[_id]['unit']? then _value += (" " + @floorplanDevices[_id]['unit'])
      return _value

    _onRemoteStateChange: (attributeString) =>
      attribute = @getAttribute(attributeString)
      unless attributeString?
        throw new Error("The floorplan device needs an #{attributeString} attribute!")

      @[attributeString] = ko.observable attribute.value()
      attribute.value.subscribe (newValue) =>
        _id = attributeString
        _tId = "#" + _id
        switch @floorplanDevices[_id].type
          when 'switch'
            @_switchOnOff(_id,newValue)
          when 'button'
            @_buttonOnOff(_id, true)
          when 'presence'
            @_presenceOnOff(_id,newValue)
          when 'contact'
            @_contactOnOff(_id,newValue)
          when 'light'
            @_lightOnOff(_id, newValue)
          when 'shutter'
            @_setShutter(_id, newValue)
          when 'sensor'
            _color = $(_tId, @svgRoot).css('fill')
            if $(_tId, @svgRoot).text() isnt ""
              $(_tId, @svgRoot).text(@_sensorFullValue(_id, newValue))
            $(_tId, @svgRoot).css('fill',_color)
          when 'sensor_bar'
            #check if extra charts are attached to _tId
            #if @floorplanDevices[_id]["bar"]? and @floorplanDevices[_id]["bar"]
            @_setBar(_id, newValue)
          when 'sensor_gauge'
            @_setGauge(_id, Number newValue)
          when 'clock'
            @_setClock(_id, Number newValue)
          when 'camera'
            return
            @_setCamera(_id,newValue)
            unless newValue
              document.location.reload()



    _onRemoteColorChange: (attributeString) =>
      attributeStringColor = attributeString + @colorAttributeExtension
      attribute = @getAttribute(attributeStringColor)
      unless attributeString?
        throw new Error("The floorplan device needs an #{attributeString} attribute!")

      @[attributeStringColor] = ko.observable attribute.value()
      attribute.value.subscribe (newColor) =>
        _id = attributeString
        _tId = "#" + _id
        _oldColor = @floorplanDevices[_id]["colorOn"]
        @floorplanDevices[_id]["colorOn"] = "fill:" + newColor
        if $(_tId, @svgRoot).attr('style') is _oldColor
          @_lightOnOff(_id, true)

    _setState: (_id, _state) ->
      @device.rest.setState {id:_id, state:_state}, global: no

    _setButton: (_id) ->
      @device.rest.buttonPressed {buttonId:_id}, global: no

    _setLight: (_id, _lightState) ->
      @device.rest.setLight {id: _id, state: _lightState}, global: no

  # register the item-class
  pimatic.templateClasses['floorplan'] = FloorplanItem
