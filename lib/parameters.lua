-- flora params

------------------------------
-- notes and todo lsit
--
-- note: see globals.lua for global variables (e.g. options.OUTPUT, etc.)
--
-- todo list: 
--  add param for scale of random rotation when the random letter ('r') is added to the instruction set
--  figure out why midi cc's mapped to exponential controlspecs don't seem to update exponentially (e.g. rqmin & rqmax)
--  add param for scale_length (currently, adding this parameter results in error messages when scale_length is decreased)
------------------------------

flora_params = {}

local specs = {}
    
specs.AMP = cs.new(0,10,'lin',0,AMPLITUDE_DEFAULT,'')

specs.NOTE_SCALAR = cs.def{
                      min=0,
                      max=20,
                      warp='lin',
                      step=0.1,
                      default=3,
                      -- quantum=1,
                      wrap=false,
                    }
              
specs.NOTE_FREQUENCY_NUMERATOR = cs.def{
                      min=1,
                      max=NOTE_FREQUENCY_NUMERATOR_MAX,
                      warp='lin',
                      step=1,
                      default=1,
                      -- quantum=1,
                      wrap=false,
                    }

specs.NOTE_FREQUENCY_DENOMINATOR = cs.def{
                      min=1,
                      max=NOTE_FREQUENCY_DENOMINATOR_MAX,
                      warp='lin',
                      step=1,
                      default=1,
                      -- quantum=1,
                      wrap=false,
                    }

specs.NOTE_FREQUENCY_SCALAR_OFFSET = cs.def{
                      min=-0.99,
                      max=0.99,
                      warp='lin',
                      step=0.01,
                      default=0,
                      -- quantum=1,
                      wrap=false,
                    }
                    
specs.TEMPO_SCALAR_OFFSET = cs.def{
                      min=tempo_scalar_offset_min,
                      max=tempo_scalar_offset_max,
                      warp='lin',
                      step=0.1,
                      default=tempo_scalar_offset_default,
                      -- quantum=1,
                      wrap=false,
                    }
--[[
specs.CFHZMIN = cs.def{
                  min=0.1,
                  max=30,
                  warp='lin',
                  step=0.01,
                  default=0.1,
                  -- quantum=1,
                  wrap=false,
                }                 

specs.CFHZMAX = cs.def{
                  min=0.1,
                  max=30,
                  warp='lin',
                  step=0.01,
                  default=0.3,
                  -- quantum=1,
                  wrap=false,
                }               
]]
specs.RQMIN = cs.def{
                min=0.1,
                max=30,
                warp='exp',
                step=0.1,
                default=1,
                -- quantum=1,
                wrap=false,
              }

specs.RQMAX = cs.def{
                min=0.1,
                max=40,
                warp='exp',
                step=0.1,
                default=5,
                -- quantum=1,
                wrap=false,
              }
              
flora_params.specs = specs

--------------------------------
-- hidden params
--------------------------------

flora_params.add_params = function(plants)
  
  params:add{
    type = "text", id = "sentence", name = "sentence"
  }
  
  params:add{type = "number", id = "page_turner", name = "page turner",
  min = 1, max = 5, default = 1, 
  action = function(x) 
    encoders_and_keys.enc(1,x-pages.index)
  end}

  params:add{type = "number", id = "active_plant_switcher", name = "active plant switcher",
  min = 1, max = 2, default = 1, 
  action = function(x) 
    -- encoders_and_keys.enc(1,x-pages.index)
    if initializing == false then
      if (x==1 and active_plant == 2) or (x==2 and active_plant == 1) then 
        switch_active_plant() 
      end
    end
  end}

  params:hide("page_turner")
  params:hide("active_plant_switcher")

--------------------------------
-- 
--------------------------------


  params:add{type = "option", id = "scale_mode", name = "scale mode",
  options = scale_names, default = 5,
  action = function() build_scale() end}
  
  params:add{type = "number", id = "root_note", name = "root note",
  min = 0, max = 127, default = root_note_default, formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end,
  action = function() build_scale() end}

  params:add_separator("outputs")
  
  params:add{type = "option", id = "crow_clock", name = "crow clock out",
    options = {"off","on"},
    action = function(value)
      if value == 2 then
        crow.output[1].action = "{to(5,0),to(5,0.05),to(0,0)}"
      end
    end}
  
  params:add{type = "option", id = "output", name = "output",
    options = options.OUTPUT,
    default = OUTPUT_DEFAULT,
    action = function(value)
      -- all_notes_off()
      if value == 4 then crow.output[2].action = "{to(5,0),to(0,0.25)}"
      elseif value == 5 then
        crow.ii.pullup(true)
        crow.ii.jf.mode(1)
      end
    end}
    
--------------------------------
-- midi params
--------------------------------

  params:add{
    type = "number", id = "midi_out_device", name = "midi out device",
    min = 1, max = 4, default = 1,
    action = function(value) midi_out_device = midi.connect(value) end
  }
  
  params:add{
    type = "number", id = "midi_out_channel1", name = "plant 1:midi out channel",
    min = 1, max = 16, default = midi_out_channel1,
    action = function(value)
      -- all_notes_off()
      midi_out_channel1 = value
    end
  }
    
  params:add{type = "number", id = "midi_out_channel2", name = "plant 2:midi out channel",
    min = 1, max = 16, default = midi_out_channel2,
    action = function(value)
      -- all_notes_off()
      midi_out_channel2 = value
    end
  }
  
  
  --------------------------------
  -- plow (envelope) parameters
  --------------------------------
  
    params:add{
    type = "number", id = "plow1_cc_channel", name = "plow 1:midi cc channel",
    min = 1, max = 16, default = plow1_cc_channel,
    action = function(value)
      -- all_notes_off()
      plow1_cc_channel = value
    end
  }

    params:add{
    type = "number", id = "plow2_cc_channel", name = "plow 2:midi cc channel",
    min = 1, max = 16, default = plow2_cc_channel,
    action = function(value)
      -- all_notes_off()
      plow2_cc_channel = value
    end
  }
  
  specs.MAX_PLOW_LEVEL = cs.new(0,MAX_AMPLITUDE,'lin',0,4,'')
  specs.MAX_PLOW_TIME = cs.new(0,MAX_ENV_LENGTH,'lin',0,2,'')
  
  params:add_separator("plow")
  
  get_node_time = function(env_id, node_id)
    local node_time = envelopes[env_id].get_envelope_arrays().times[node_id]
    return node_time 
  end

  get_node_level = function(env_id, node_id)
    return envelopes[env_id].get_envelope_arrays().levels[node_id]
  end

  get_node_curve = function(env_id, node_id)
    return envelopes[env_id].get_envelope_arrays().curves[node_id]
  end

  params:add_number("num_plow1_controls", "num_plow1_controls", 3, MAX_ENVELOPE_NODES, 5)
  params:hide("num_plow1_controls")

  params:add_number("num_plow2_controls", "num_plow2_controls", 3, MAX_ENVELOPE_NODES, 5)
  params:hide("num_plow2_controls")

  
  local reset_plow_controls = function(plow_id)
    print("reset")
    clock.sleep(0.5)
    -- set the values of the individual envelope nodes 
    local env = plow_id == 1 and envelopes[1].graph_nodes or envelopes[2].graph_nodes
    local num_plow1_controls = #env
    local num_plow2_controls = #env
    local num_plow_controls = plow_id == 1 and num_plow1_controls or num_plow2_controls
    local plow_times = plow_id == 1 and plow1_times or plow2_times
    for i=MAX_ENVELOPE_NODES, 1, -1
    do

      local param_id_name, param_name, get_control_value_fn, min_val, max_val

      -- update time
      param_id_name = "plow".. plow_id.."_time" .. i
      param_name = "plow".. plow_id.."-control" .. i .. "-time"
      get_control_value_fn = get_node_time
      local control_value = get_control_value_fn(1,i) or 1
      local param = params:lookup_param(param_id_name)
      local prev_val = (env[i-1] and env[i-1].time) or 0
      local next_val = env[i+1] and env[i+1].time or envelopes[plow_id].env_time_max
      local controlspec = cs.new(prev_val,next_val,'lin',0,control_value,'')
      if env[i] then
        param.controlspec = controlspec
      end

      -- update level
      param_id_name = "plow".. plow_id.."_level" .. i
      param_name = "plow".. plow_id.."-control" .. i .. "-level"
      get_control_value_fn = get_node_level
      local control_value = get_control_value_fn(1,i) or 1
      local param = params:lookup_param(param_id_name)
      local max_val = envelopes[plow_id].env_level_max
      local controlspec = cs.new(0,max_val,'lin',0,control_value,'')
      if env[i] then
        param.controlspec = controlspec
      end
    end
  end  

  local update_plow_controls = function (x, plow_id)
    local num_plow_controls = plow_id == 1 and envelopes[1].get_envelope_arrays().segments or envelopes[2].get_envelope_arrays().segments
    if plow_id == 1 then
      for i=1,MAX_ENVELOPE_NODES,1
      do
        if i <= num_plow_controls then
          params:show(plow1_times[i])
          if i > 1 then
            if i~=num_plow_controls then 
              params:show(plow1_levels[i]) 
            else 
              params:hide(plow2_levels[i]) 
            end
            params:show(plow1_curves[i])
          end 
        else
          params:hide(plow1_times[i])
          params:hide(plow1_levels[i])
          params:hide(plow1_curves[i])
        end
      end
    else
      for i=1,MAX_ENVELOPE_NODES,-1
      do
        if i <= num_plow_controls then
          params:show(plow2_times[i])
          if i > 1 then
            if i~=num_plow_controls then 
              params:show(plow2_levels[i]) 
            else 
            end
            params:show(plow2_curves[i])
          end 
        else
          params:hide(plow2_times[i])
          params:hide(plow2_levels[i])
          params:hide(plow2_curves[i])
        end
      end
    end
    -- clock.run(set_dirty)
  end
  
  params:set_action("num_plow1_controls", 
    function(x)
      if initializing == false then
        update_plow_controls(x,1)
        clock.run(reset_plow_controls,1)
      end
    end
  )

  params:set_action("num_plow2_controls", 
    function(x)
      if initializing == false then
        update_plow_controls(x,2)
        clock.run(reset_plow_controls,2)
      end
    end
  )
  
  local init_plow_controls = function(plow_id)
    
    -- set the envelope's overall max time
    params:add{
      type="control",
      id = plow_id == 1 and "plow1_max_time" or "plow2_max_time",
      controlspec=specs.MAX_PLOW_TIME,
      action=function(x) 
        if initializing == false then
          envelopes[plow_id].set_env_time(x) 
          clock.run(reset_plow_controls,plow_id)
        end
      end
    }

    -- set the envelope's overall max level
    params:add{
      type="control",
      id = plow_id == 1 and "plow1_max_level" or "plow2_max_level",
      controlspec=specs.MAX_PLOW_LEVEL,
      action=function(x) 
        if initializing == false then
          envelopes[plow_id].set_env_max_level(x) 
          clock.run(reset_plow_controls,plow_id)
        end
      end
    }
  
    -- set the values of the individual envelope nodes 
    local env = plow_id == 1 and envelopes[1].graph_nodes or envelopes[2].graph_nodes
    local num_plow1_controls = envelopes[1].get_envelope_arrays().segments
    local num_plow2_controls = envelopes[2].get_envelope_arrays().segments
    local num_plow_controls = plow_id == 1 and num_plow1_controls or num_plow2_controls
    local plow_times = plow_id == 1 and plow1_times or plow2_times
    local plow_levels = plow_id == 1 and plow1_levels or plow2_levels
    local plow_curves = plow_id == 1 and plow1_curves or plow2_curves
    
    for i=1, MAX_ENVELOPE_NODES, 1
    do
      for j=1, 3, 1
      do
        local param_id_name, param_name, plow_control_type, get_control_value_fn, min_val, max_val
        if j == 1 then
          plow_control_type = "time"
          param_id_name = "plow".. plow_id.."_time" .. i
          param_name = "plow".. plow_id.."-control" .. i .. "-time"
          get_control_value_fn = get_node_time
          min_val = 0
          max_val = MAX_ENV_LENGTH
        elseif j == 2 then
          plow_control_type = "level"
          param_id_name = "plow".. plow_id.."_level" .. i
          param_name = "plow".. plow_id.."-control" .. i .. "-level"
          get_control_value_fn = get_node_level
          min_val = 0
          max_val = MAX_AMPLITUDE
        else 
          plow_control_type = "curve"
          param_id_name = "plow".. plow_id.."_curve" .. i
          param_name = "plow".. plow_id.."-control" .. i .. "-curve"
          get_control_value_fn = get_node_curve
          min_val = CURVE_MIN
          max_val = CURVE_MAX
        end        
        
        local control_value = get_control_value_fn(1,i) or 1
        
        params:add{
          type = "control", 
          id = param_id_name,
          name = param_name,
          controlspec = cs.new(min_val,max_val,'lin',0,control_value,''),
          action=function(x) 
            local param = params:lookup_param(param_id_name)
            local new_val = x
            
            if plow_control_type == "time" then
              local prev_param_id_name = "plow".. plow_id.."_time" .. i-1
              local prev_val = (env[i-1] and params:get(prev_param_id_name)) or 0
              local next_param_id_name = "plow".. plow_id.."_time" .. i+1
              local next_val = env[i+1] and params:get(next_param_id_name) or ENV_TIME_MAX
              if env[i] then
                env[i][plow_control_type] = new_val
                param.controlspec.minval = prev_val
                param.controlspec.maxval = next_val
              end
              new_val = util.clamp(new_val, prev_val, next_val)
              -- new_val = util.clamp(new_val, min_val, max_val)
              param:set(new_val)
              
            else
              new_val = util.clamp(new_val, min_val, max_val)
              if env[i] then
                env[i][plow_control_type] = new_val
              end
              param:set(new_val)
            end
            envelopes[plow_id].graph:edit_graph(env)
            clock.run(envelopes[plow_id].update_engine, env)
            -- envelopes[plow_id].update_engine(env)
          end
        }
      end
    end
    for i=num_plow_controls+1,MAX_ENVELOPE_NODES,1
    do
      params:hide(plow_times[i])
      params:hide(plow_levels[i])
      params:hide(plow_curves[i])
    end
    params:hide(plow_levels[1])
    params:hide(plow_curves[1])
    params:hide(plow_levels[num_plow_controls])
      
  end

  params:add_group("plow 1 controls",MAX_ENVELOPE_NODES*3 - 1)
  init_plow_controls(1)
  
  params:add_group("plow 2 controls",MAX_ENVELOPE_NODES*3 - 1)
  init_plow_controls(2)

  --------------------------------
  -- water parameters
  --------------------------------
  params:add_separator("water")

  params:add{
    type = "number", id = "water_cc_channel", name = "water:midi cc channel",
    min = 1, max = 16, default = water_cc_channel,
    action = function(value)
      -- all_notes_off()
      water_cc_channel = value
    end
  }

  params:add{
    type="control",
    id="amp",
    controlspec=specs.AMP,
    action=function(x) engine.amp(x) end
  }
  
  params:add{
    type = "control", 
    id = "rqmin", 
    name = "rqmin (/1000)",  
    controlspec = specs.RQMIN,
    action=function(x)
      engine.rqmin(x/1000) 
    end
  }

  params:add{
    type = "control", 
    id = "rqmax", 
    name = "rqmax (/1000)",  
    controlspec = specs.RQMAX,
    action=function(x)
      engine.rqmax(x/1000) 
    end
  }


  params:add{
    type = "control", 
    id = "note_scalar", 
    name = "note scalar",  
    controlspec = specs.NOTE_SCALAR, 
    action=function(x)
      for i=1, #plants, 1
      do
        plants[i].sounds.set_note_scalar(x)
      end
    end
  }
  
  
  local active_cf_scalars = {}
  params:add_number("num_active_cf_scalars", "num cf scalars", 1, num_cf_scalars_max, num_cf_scalars_default)

  local reset_cf_scalars = function()
    active_cf_scalars = {}
    local num_active_cf_scalars = params:get("num_active_cf_scalars")
    for i=1, num_active_cf_scalars, 1
    do
      local cf_scalar = params:get(cf_scalars[i])
      table.insert(active_cf_scalars,cf_scalar)
    end
    -- engine.set_cfScalars(table.unpack(active_cf_scalars))
  end
  
  params:add_group("cf scalars",num_cf_scalars)

  params:set_action("num_active_cf_scalars", 
    function(x) 
      -- engine.set_numCFScalars(x)
      reset_cf_scalars()
      local num_active_cf_scalars = params:get("num_active_cf_scalars")
      for i=num_cf_scalars,1,-1 
      do
        if i > num_active_cf_scalars then
          params:hide(cf_scalars[i])
        else
          params:show(cf_scalars[i])
        end
      end
    end
  )
  
  
  for i=1, num_cf_scalars, 1
  do
    params:add{
      type = "option", 
      id = cf_scalars[i], 
      name = "cf scalar" .. i,
      options = options.SCALARS,
      default = 2
    }
    
    params:set_action(cf_scalars[i], 
      function(x) 
        reset_cf_scalars()       
      end
    )

    params:hide(cf_scalars[i])
  end
  
--------------------------------
  

  params:add{
    type = "option", 
    id = "plant_1_note_duration", 
    name = "plant 1: note duration",
    options = options.NOTE_DURATIONS,
    default = NOTE_DURATION_INDEX_DEFAULT_1,
    action=function(x)
      plants[1].sounds.set_note_duration(options.NOTE_DURATIONS[x])
    end
  } 
  
  params:add{
    type = "option", 
    id = "plant_2_note_duration", 
    name = "plant 2: note duration",
    options = options.NOTE_DURATIONS,
    default = NOTE_DURATION_INDEX_DEFAULT_2,
    action = function(x) 
      plants[2].sounds.set_note_duration(options.NOTE_DURATIONS[x])
    end
  }
  

  local num_note_frequencies = 6
  params:add_number("num_note_frequencies", "# note freqs", 1, num_note_frequencies, 1)

  function get_note_frequencies(scalar)
    local scalar = scalar or 1
    local frequencies = {}
    local num_active_note_frequencies = params:get("num_note_frequencies")
    for i=1, num_active_note_frequencies, 1
    do
      local frequency_n = params:get(note_frequency_numerators[i])
      local frequency_d = params:get(note_frequency_denominators[i])
      local frequency_o = params:get(note_frequency_offsets[i])
      local frequency = frequency_n/(frequency_d+frequency_o)
      table.insert(frequencies, frequency*scalar)
    end
    return frequencies
  end

  local reset_note_frequencies = function()
    
    
    local tempo_scalar_offset = params:get("tempo_scalar_offset")
    local clock_tempo = params:get("clock_tempo")
    local clock_tempo_scalar = clock_tempo/(60 * tempo_scalar_offset)
    tempo_offset_note_frequencies = get_note_frequencies(clock_tempo_scalar)
    --local engine_frequencies = get_note_frequencies(clock_tempo_scalar)
    --engine.set_frequencies(table.unpack(engine_frequencies))
    note_frequencies = get_note_frequencies()
    clock.run(set_dirty)
  end

  params:add_group("note freqs",num_note_frequencies*3)

  params:set_action("num_note_frequencies", 
    function(x) 
      -- engine.set_numFrequencies(x)
      reset_note_frequencies()
      
      local num_active_note_frequencies = params:get("num_note_frequencies")
      for i=num_note_frequencies,1,-1
      do
        if i > num_active_note_frequencies then
          params:hide(note_frequency_numerators[i])
          params:hide(note_frequency_denominators[i])
          params:hide(note_frequency_offsets[i])
          
        else
          params:show(note_frequency_numerators[i])        
          params:show(note_frequency_denominators[i])
          params:show(note_frequency_offsets[i])        
        end
      end
    end
  )
  
  
  for i=1, num_note_frequencies, 1
  do
    params:add{
        type = "control", 
        id = note_frequency_numerators[i], 
        name = "note freq"..i..": numerator",  
        controlspec = specs.NOTE_FREQUENCY_NUMERATOR, 
        action=function(x) 
          reset_note_frequencies()       
        end
     }

    params:add{
        type = "control", 
        id = note_frequency_denominators[i], 
        name = "note freq"..i..": denominator",  
        controlspec = specs.NOTE_FREQUENCY_DENOMINATOR, 
        action=function(x) 
          reset_note_frequencies()       
        end
     }

    params:add{
        type = "control", 
        id = note_frequency_offsets[i], 
        name = "note freq"..i..": offset",  
        controlspec = specs.NOTE_FREQUENCY_SCALAR_OFFSET, 
        action=function(x) 
          reset_note_frequencies()       
        end
     }
    
    params:hide(note_frequency_numerators[i])
    params:hide(note_frequency_denominators[i])
    params:hide(note_frequency_offsets[i])
  end

  
  params:add{
    type = "control",
    id = "tempo_scalar_offset", 
    name = "tempo scalar offset", 
    controlspec = specs.TEMPO_SCALAR_OFFSET
  }
  
  params:set_action("tempo_scalar_offset", 
    function()
      reset_note_frequencies()
    end
  )

  -- overwrite clock tempo action
  params:set_action("clock_tempo",
    function(bpm)
      local source = params:string("clock_source")
      if source == "internal" then clock.internal.set_tempo(bpm)
      elseif source == "link" then clock.link.set_tempo(bpm) end
      norns.state.clock.tempo = bpm
      reset_note_frequencies()
    end)

  -- params:set_action("clock_tempo", 
  --   function()
  --      reset_note_frequencies()
  --   end
  -- )
    
  --set the reverb input engine to -10db
  params:set(13, -10)
  params:bang()
  reset_note_frequencies()
  

--[[
  params:add{
    type = "control", 
    id = "cfhzmin", 
    name = "cfhzmin",  
    controlspec = specs.CFHZMIN,
    action=function(x)
      engine.cfhzmin(x) 
    end
  }

  params:add{
    type = "control", 
    id = "cfhzmax", 
    name = "cfhzmax",  
    controlspec=specs.CFHZMAX,
    action=function(x)
      engine.cfhzmax(x) 
    end
  }
]]
  
--[[
   params:add{type = "control", id = "lsf", name = "lsf",  controlspec=cs.def{
      min=0,
      max=500,
      warp='lin',
      step=1,
      default=0,
      -- quantum=1,
      wrap=false,
    },
    action=function(x)
      engine.lsf(x) 
    end
  }
  
     params:add{type = "control", id = "ldb", name = "ldb",  controlspec=cs.def{
      min=0,
      max=500,
      warp='lin',
      step=1,
      default=100,
      -- quantum=1,
      wrap=false,
    },
    action=function(x)
      engine.ldb(x) 
    end
  }
]]

end

return flora_params
