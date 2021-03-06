angular.module('NgDrag', [])
  .factory 'DragHolder', ->
    object = { scope: '', dragging: '', context: '' }

    object.set = (scope,dragging,context) ->
      this.scope    = scope
      this.dragging = dragging
      this.context  = context

    object.get = ->
        return this

    return object
  .directive 'ngPositionable', (DragHolder) ->
    link: (scope, element, attributes, ngModelCtrl) ->
      el = element[0]
      element.css('transition', '0.3s all')
      el.draggable = true
      el.addEventListener 'dragstart', (e) ->
        this.classList.add('drag')
        DragHolder.set scope,attributes.ngPositionable,attributes.ngContext
        e.stopPropagation()
      el.addEventListener 'dragend',(e) ->
        this.classList.remove('drag')
      el.droppable = true
      el.addEventListener 'dragover', (e) ->
        e.dataTransfer.dropEffect = 'move'
        e.preventDefault()
        e.stopPropagation()
        this.classList.add('over')
      el.addEventListener 'dragenter', (e) ->
        e.preventDefault()
        e.stopPropagation()
        this.classList.add('over')
      el.addEventListener 'dragleave', (e) ->
        this.classList.remove('over')
        e.preventDefault()
      el.addEventListener 'drop', (e) ->
        e.stopPropagation() if (e.stopPropagation)
        this.classList.remove('over')
        raw_factory = attributes.ngPositionable.split('_')
        factory=[]
        for word in raw_factory
          factory.push(word.charAt(0).toUpperCase() + word.slice(1))
        factory = factory.join('')
        dragged = DragHolder.get()
        dragging = dragged.scope[dragged.dragging]
        if dragged.context
          draggingContext = dragged.scope[dragged.context]
          droppingContext = scope[attributes.ngContext]
          if draggingContext != droppingContext
            dragged.scope[factory].splice(dragged.scope[factory].indexOf(dragging),1)
            scope[factory].push(dragging)
        dropping = scope[attributes.ngPositionable]
        if attributes.ngDisabled
          disabled = attributes.ngDisabled.split('!')
          disabled[0] = '!' if disabled.length > 1
          bool = scope.$parent[disabled.pop()]
          bool = !bool if disabled.length > 0
        else
          bool = false
        unless bool
          scope.setPosition(dragging,dropping,draggingContext,droppingContext,attributes.ngContext,factory)
    controller: ($scope, $element, $filter, $injector) ->
      $scope.setPosition = (dragging,dropping,draggingContext,droppingContext,context,factory) ->
        unless dragging == dropping
          orderedArray = $filter('orderBy')($scope[factory], 'position')
          index = orderedArray.indexOf(dropping)
          unless index == 0
            dragging.position = String(dropping.position - (dropping.position - orderedArray[index - 1].position) / 2)
          else
            dragging.position = String(dropping.position / 2)
          object = {id: dragging.id, position: dragging.position}
          object[context + '_id'] = droppingContext.id if context
          list = $injector.get(factory)
          list.update object, (returnData) ->
            dragging = returnData

  .directive 'ngDrag', ->
    link: (scope, element, attributes, ngModelCtrl) ->
      callFunction = attributes.ngDrag
      el = element[0]
      el.draggable = true
      el.addEventListener 'dragstart', (e) ->
        e.dataTransfer.setData('html',el)
        this.classList.add('drag')
        scope.$eval(callFunction)
      el.addEventListener 'dragend',(e) ->
        this.classList.remove('drag')

  .directive 'ngDrop', ->
    link: (scope, element, attributes, ngModelCtrl) ->
      callFunction = attributes.ngDrop
      el = element[0]
      el.droppable = true
      el.addEventListener 'dragover', (e) ->
        e.dataTransfer.dropEffect = 'move'
        e.preventDefault()
        this.classList.add('over')
      el.addEventListener 'dragenter', (e) ->
        e.preventDefault()
        this.classList.add('over')
      el.addEventListener 'dragleave', (e) ->
        this.classList.remove('over')
        e.preventDefault()
      el.addEventListener 'drop', (e) ->
        e.stopPropagation() if (e.stopPropagation)
        this.classList.remove('over')
        scope.$eval(callFunction)

  .directive 'ngChangeDebounce', ($timeout) ->
    restrict: 'A',
    require: 'ngModel',
    link: (scope, element, attr, ngModelCtrl) ->
      return if (attr.type == 'radio' || attr.type == 'checkbox')
      callFunction = attr.ngChangeDebounce
      element.bind 'keyup', ->
        $timeout.cancel(scope.debounce)
        scope.debounce = $timeout ->
          scope.$eval(callFunction)
        ,750
