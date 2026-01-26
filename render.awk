BEGIN {
  skip = 0        # whether to skip printing
  matched = 0     # whether a previous branch matched
}

/^#if[ \t]+/ {
  var = $2
  matched = (var in ENVIRON)
  skip = !matched
  next
}

/^#elif[ \t]+/ {
  if (matched) {
    skip = 1
  } else {
    var = $2
    matched = (var in ENVIRON)
    skip = !matched
  }
  next
}

/^#else/ {
  skip = matched
  matched = 1
  next
}

/^#end/ {
  skip = 0
  matched = 0
  next
}

!skip {
  line = $0
  while (match(line, /\$\{[A-Za-z_][A-Za-z0-9_]*\}/)) {
    var = substr(line, RSTART+2, RLENGTH-3)
    gsub("\\$\\{"var"\\}", ENVIRON[var], line)
  }
  print line
}
