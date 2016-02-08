# SkNN-ruby
Structured kNN algorithm implementation in ruby.

SkNN is an algorithm for sequence tagging or classification.
# Usage
## install dependencies
```
bundle install
```
## Learn model

Example of learning pen written digits from http://archive.ics.uci.edu/ml/datasets/UJI+Pen+Characters
```
ruby sknn.rb -l model.dat data/nums/*
```
## Execute classification
```
ruby sknn.rb -x model.dat -o result.txt data/light_num_test.csv
```
