embed_spec = 
{
  "width": 500,
  "height": 500,
  "padding": {"top": 0,"bottom": 0,"left": 0,"right": 0},


  "data": [
    {
      "name": "edges",
      "url": "/graph",
      "format": {"type": "json","property": "edges"}
    },
    {
      "name": "nodes",
      "url": "/graph",
      "format": {"type": "json","property": "nodes"},
      "transform": [
        {
          "type": "force",
          "links": "edges",
          "linkDistance": 70,
          "charge": -80,
          "iterations": 1000
        }
      ]
    }
  ],
  
  "marks": [
    {
      "type": "symbol",
      "from": {"data": "nodes"},
      "properties": {
        "enter": {
          "shape": "circle",
          "fillOpacity": {"value": 0.3},
          "stroke": {"value": "steelblue"}
        },
        "update": {
          "x": {"field": "layout_x"},
          "y": {"field": "layout_y"},
          "fill": {"value": "steelblue"}
        },
        "hover": {"fill": {"value": "#f00"}}
      }
    }
  ]
}


//-----------------------------------------------------------
{
  "width": 500,
  "height": 500,
  "padding": {"top": 0,"bottom": 0,"left": 0,"right": 0},
  "data": [
    {
      "name": "edges",
      "values": {
        "nodes": [
          {"id": 0,"name": "A","value": 1},
          {"id": 1,"name": "B","value": 1}
        ],
        "edges": [{"source": 0,"target": 1}],
        "loops": [
          {"source": 0,"target": 0},
          {"source": 1,"target": 1}
        ]
      },
      "format": {"type": "json","property": "edges"}
    },
    {
      "name": "nodes",
      "values": {
        "nodes": [
          {"id": 0,"name": "A","value": 1},
          {"id": 1,"name": "B","value": 1}
        ],
        "edges": [{"source": 0,"target": 1}],
        "loops": [
          {"source": 0,"target": 0},
          {"source": 1,"target": 1}
        ]
      },
      "format": {"type": "json","property": "nodes"},
      "transform": [
        {
          "type": "force",
          "links": "edges",
          "linkDistance": 120,
          "charge": -80,
          "iterations": 1000
        }
      ]
    }
  ],
  "marks": [
    {
      "type": "path",
      "from": {
        "data": "edges",
        "transform": [
          {
            "type": "lookup",
            "on": "nodes",
            "keys": ["source","target"],
            "as": ["_source","_target"]
          },
          {"type": "linkpath","shape": "line"}
        ]
      },
      "properties": {
        "update": {
          "path": {"field": "layout_path"},
          "stroke": {"value": "#ccc"},
          "strokeWidth": {"value": 0.5}
        }
      }
    },
    {
      "type": "symbol",
      "from": {"data": "nodes"},
      "properties": {
        "enter": {
          "shape": "circle",
          "fillOpacity": {"value": 0.3},
          "stroke": {"value": "steelblue"},
          "size": {"value": 500}
        },
        "update": {
          "x": {"field": "layout_x"},
          "y": {"field": "layout_y"},
          "fill": {"value": "steelblue"}
        },
        "hover": {"fill": {"value": "#f00"}}
      }
    },
    {
      "type": "rect",
      "from": {
        "data": "edges",
        "transform": [
          {
            "type": "lookup",
            "on": "nodes",
            "onKey": "id",
            "keys": ["target"],
            "as": ["coords_to"]
          },
          {
            "type": "lookup",
            "on": "nodes",
            "onKey": "id",
            "keys": ["source"],
            "as": ["coords_from"]
          }
        ]
      },
      "properties": {
        "update": {
          "interpolate": {"value": "cardinal"},
          "x":  {"field": "coords_to.layout_x"},
          "y":  {"field": "coords_to.layout_y"},
          "x2": {"field": "coords_from.layout_x"},
          "y2": {"field": "coords_from.layout_y"},
          "fill": {"value": "red"},
          "stroke": {"value": "red"},
          "strokeWidth": {"value": 1}
        }
      }
    },
    {
      "type": "text",
      "from": {"data": "nodes"},
      "properties": {
        "enter": {
          "text": {"field": "name"},
          "stroke": {"value": "black"},
          "align": {"value": "center"},
          "baseline": {"value": "middle"}
        },
        "update": {
          "x": {"field": "layout_x"},
          "y": {"field": "layout_y"},
          "fill": {"value": "steelblue"}
        }
      }
    }
  ]
}