(function() {
  var BeatDetector, main,
    __slice = [].slice;

  BeatDetector = (function() {
    var BEAT_MIN_DISTANCE_SAMPLES, MAX_BPM_DETECTED, MAX_DISTANCE_MULTIPLIER, MAX_SEARCH_WINDOW_SIZE, MINIMUM_THRESHOLD, TARGET_SAMPLE_RATE;

    BEAT_MIN_DISTANCE_SAMPLES = 10000;

    MAX_DISTANCE_MULTIPLIER = 32;

    MAX_BPM_DETECTED = 300;

    TARGET_SAMPLE_RATE = 44100;

    MAX_SEARCH_WINDOW_SIZE = 3;

    MINIMUM_THRESHOLD = 1;

    function BeatDetector() {}

    BeatDetector.prototype.detectBeats = function(pcmAudioData, previousEnergyVarianceCoefficient, _previousAverageEnergyCoefficient, _samplesPerInstantEnergy, _numberOfPreviousEnergies, _maxBpm, _sampleRate) {
      this._previousAverageEnergyCoefficient = _previousAverageEnergyCoefficient;
      this._samplesPerInstantEnergy = _samplesPerInstantEnergy;
      this._numberOfPreviousEnergies = _numberOfPreviousEnergies;
      this._maxBpm = _maxBpm;
      this._sampleRate = _sampleRate;
      this._samplesPerInstantEnergy = Math.floor(this._samplesPerInstantEnergy * this._sampleRate / TARGET_SAMPLE_RATE);
      this._numberOfPreviousEnergies = Math.floor(this._numberOfPreviousEnergies * this._sampleRate / TARGET_SAMPLE_RATE);
      this._trackLength = pcmAudioData.length / this._sampleRate;
      this.maximumEnergies = [];
      this._beatMinDistanceSamples = this.bpmToDistance(this._maxBpm);
      this._findBeats(pcmAudioData);
      this._previousAverageEnergyCoefficient -= 0.1;
      while (this.maximumEnergies.length < this._trackLength && this._previousAverageEnergyCoefficient > MINIMUM_THRESHOLD) {
        this._previousAverageEnergyCoefficient -= 0.1;
        this._findBeats(pcmAudioData);
      }
      this._calculateTempo();
      this.beats = this.maximumEnergies.slice(0);
      this._removeOutOfTimeBeats();
      return this._addBeatsInGaps();
    };

    BeatDetector.prototype._findBeats = function(pcmAudioData) {
      var currentIndex, currentTimeSeconds, distanceBetweenBeatIndexes, i, instantEnergySum, lastBeatIndex, minDistance, pcm, previousEnergies, previousEnergiesAverage, previousEnergiesIndex, previousEnergiesSum, previousEnergy, threshold, _i, _j, _len, _len1, _results;
      previousEnergies = [];
      this.distanceInEnergyIndexBetweenBeats = [];
      this.maximumEnergies = [];
      lastBeatIndex = 0;
      this.energies = [];
      this.averageEnergies = [];
      this.maxEnergy = 0;
      this._maxCountIndex = 0;
      this._maxBeatIndex = 0;
      this._maxBeatValue = 0;
      previousEnergiesIndex = 0;
      instantEnergySum = 0;
      _results = [];
      for (i = _i = 0, _len = pcmAudioData.length; _i < _len; i = ++_i) {
        pcm = pcmAudioData[i];
        instantEnergySum += pcm * pcm;
        if (i % this._samplesPerInstantEnergy !== 0) {
          continue;
        }
        if (instantEnergySum > this.maxEnergy) {
          this.maxEnergy = instantEnergySum;
        }
        currentTimeSeconds = i / this._sampleRate;
        this.energies.push([currentTimeSeconds, instantEnergySum]);
        if (previousEnergies.length < this._numberOfPreviousEnergies) {
          previousEnergies.push(instantEnergySum);
        } else {
          previousEnergiesSum = 0;
          for (_j = 0, _len1 = previousEnergies.length; _j < _len1; _j++) {
            previousEnergy = previousEnergies[_j];
            previousEnergiesSum += previousEnergy;
          }
          previousEnergiesAverage = previousEnergiesSum / previousEnergies.length;
          threshold = this._previousAverageEnergyCoefficient * previousEnergiesAverage;
          this.averageEnergies.push([currentTimeSeconds, threshold]);
          if (instantEnergySum > threshold) {
            currentIndex = this.averageEnergies.length - 1;
            distanceBetweenBeatIndexes = currentIndex - lastBeatIndex;
            minDistance = this._beatMinDistanceSamples;
            if (distanceBetweenBeatIndexes > minDistance) {
              lastBeatIndex = currentIndex;
              this.maximumEnergies.push(currentTimeSeconds);
              this.distanceInEnergyIndexBetweenBeats.push({
                distance: distanceBetweenBeatIndexes,
                energy: instantEnergySum,
                index: currentIndex,
                maximumEnergiesIndex: this.maximumEnergies.length - 1
              });
            }
          }
          previousEnergies.splice(previousEnergiesIndex, 1, instantEnergySum);
        }
        previousEnergiesIndex++;
        if (previousEnergiesIndex >= this._numberOfPreviousEnergies) {
          previousEnergiesIndex = 0;
        }
        _results.push(instantEnergySum = 0);
      }
      return _results;
    };

    BeatDetector.prototype._calculateTempo = function() {
      var beatDistanceCount, classAboveModalClass, classBelowModalClass, d1, d2, data, distance, distanceBpm, frequencyOfClassAboveModalClass, frequencyOfClassBellowModalClass, i, lowerBoundOfModalClass, maxCountSoFar, maxDistanceBetwenBeats, middleOfClassAboveModalClass, middleOfClassBelowModalClass, middleOfModalClass, mode, upperBoundOfModalClass, widthOfModalClass, _i, _j, _k, _len, _len1, _ref, _ref1;
      maxDistanceBetwenBeats = this._numberOfPreviousEnergies * MAX_DISTANCE_MULTIPLIER;
      this.beatDistanceCounts = [];
      for (i = _i = 0; 0 <= maxDistanceBetwenBeats ? _i <= maxDistanceBetwenBeats : _i >= maxDistanceBetwenBeats; i = 0 <= maxDistanceBetwenBeats ? ++_i : --_i) {
        this.beatDistanceCounts.push({
          count: 0,
          beats: []
        });
      }
      _ref = this.distanceInEnergyIndexBetweenBeats;
      for (_j = 0, _len = _ref.length; _j < _len; _j++) {
        data = _ref[_j];
        distance = data.distance;
        distanceBpm = this.distanceToBpm(distance);
        if (distance < maxDistanceBetwenBeats) {
          if (distanceBpm > this._maxBpm) {
            distance *= 2;
          } else if (distanceBpm < 80) {
            distance = Math.floor(distance / 2);
          }
          this.beatDistanceCounts[distance].count++;
          this.beatDistanceCounts[distance].beats.push(data);
        }
      }
      this._maxCountIndex = 0;
      maxCountSoFar = 0;
      _ref1 = this.beatDistanceCounts;
      for (i = _k = 0, _len1 = _ref1.length; _k < _len1; i = ++_k) {
        beatDistanceCount = _ref1[i];
        if (beatDistanceCount.count > maxCountSoFar) {
          maxCountSoFar = beatDistanceCount.count;
          this._maxCountIndex = i;
          this._principalBeat = beatDistanceCount;
        }
      }
      middleOfModalClass = this.distanceToBpm(this._maxCountIndex);
      middleOfClassAboveModalClass = this.distanceToBpm(this._maxCountIndex - 1);
      middleOfClassBelowModalClass = this.distanceToBpm(this._maxCountIndex + 1);
      upperBoundOfModalClass = middleOfClassAboveModalClass - (middleOfClassAboveModalClass - middleOfModalClass) / 2;
      lowerBoundOfModalClass = middleOfClassBelowModalClass + (middleOfModalClass - middleOfClassBelowModalClass) / 2;
      widthOfModalClass = upperBoundOfModalClass - lowerBoundOfModalClass;
      classBelowModalClass = this.beatDistanceCounts[this._maxCountIndex + 1];
      if (classBelowModalClass != null) {
        frequencyOfClassBellowModalClass = classBelowModalClass.count;
      } else {
        frequencyOfClassBellowModalClass = 0;
      }
      classAboveModalClass = this.beatDistanceCounts[this._maxCountIndex - 1];
      if (classAboveModalClass != null) {
        frequencyOfClassAboveModalClass = classAboveModalClass.count;
      } else {
        frequencyOfClassAboveModalClass = 0;
      }
      d1 = maxCountSoFar - frequencyOfClassBellowModalClass;
      d2 = maxCountSoFar - frequencyOfClassAboveModalClass;
      mode = lowerBoundOfModalClass + (d1 / (d1 + d2)) * widthOfModalClass;
      this._meanCount = this.bpmToDistance(mode);
      return this.bpm = mode;
    };

    BeatDetector.prototype._removeOutOfTimeBeats = function() {
      var beat, distance, distanceLength, distanceSoFar, energy, i, index, indexesToRemove, lowerBound, maxMaximumEnergy, maximumEnergiesIndex, maximumEnergyIndex, upperBound, _i, _j, _k, _l, _len, _ref, _ref1, _results;
      maximumEnergyIndex = 0;
      maxMaximumEnergy = 0;
      if (this._principalBeat != null) {
        _ref = this._principalBeat.beats;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          beat = _ref[_i];
          if (beat.energy > maxMaximumEnergy) {
            maximumEnergiesIndex = beat.maximumEnergiesIndex;
            maxMaximumEnergy = beat.energy;
          }
        }
      }
      this.principalBeatTime = this.beats[maximumEnergiesIndex];
      this._maxEnergyDistance = this._meanCount;
      lowerBound = this._maxEnergyDistance - MAX_SEARCH_WINDOW_SIZE;
      upperBound = this._maxEnergyDistance + MAX_SEARCH_WINDOW_SIZE;
      indexesToRemove = [];
      distanceSoFar = 0;
      if (maximumEnergyIndex > 0) {
        for (i = _j = maximumEnergiesIndex; _j >= 0; i = _j += -1) {
          energy = this.distanceInEnergyIndexBetweenBeats[i];
          distance = energy.distance + distanceSoFar;
          if (distance < lowerBound || distance > upperBound) {
            distanceSoFar += energy.distance;
            if (distanceSoFar > upperBound) {
              distanceSoFar = 0;
            }
            indexesToRemove.splice(0, 0, i);
          } else {
            distanceSoFar = 0;
          }
        }
      }
      distanceSoFar = 0;
      distanceLength = this.distanceInEnergyIndexBetweenBeats.length - 1;
      for (i = _k = 0; 0 <= distanceLength ? _k <= distanceLength : _k >= distanceLength; i = 0 <= distanceLength ? ++_k : --_k) {
        energy = this.distanceInEnergyIndexBetweenBeats[i];
        distance = energy.distance + distanceSoFar;
        if (distance < lowerBound || distance > upperBound) {
          distanceSoFar += energy.distance;
          if (distanceSoFar > this._maxEnergyDistance + MAX_SEARCH_WINDOW_SIZE) {
            distanceSoFar = 0;
          }
          indexesToRemove.push(i);
        } else {
          distanceSoFar = 0;
        }
      }
      _results = [];
      for (i = _l = _ref1 = indexesToRemove.length - 1; _l >= 0; i = _l += -1) {
        index = indexesToRemove[i];
        _results.push(this.beats.splice(index, 1));
      }
      return _results;
    };

    BeatDetector.prototype._getSecondsPerInstantEnergy = function() {
      return this._samplesPerInstantEnergy / this._sampleRate;
    };

    BeatDetector.prototype.distanceToTime = function(distance) {
      var secondsPerInstantEnegy;
      secondsPerInstantEnegy = this._getSecondsPerInstantEnergy();
      return distance * secondsPerInstantEnegy;
    };

    BeatDetector.prototype.distanceToBpm = function(distance) {
      return 60 / this.distanceToTime(distance);
    };

    BeatDetector.prototype.bpmToDistance = function(bpm) {
      return 60 / bpm / this._getSecondsPerInstantEnergy();
    };

    BeatDetector.prototype._addBeatsInGaps = function() {
      var b, beat, beatsToInsert, gap, i, j, lowerBound, meanLength, newBeats, newTime, nextBeat, nextTime, numberOfNewBeats, numberOfNewBeatsInserted, subdivisions, upperBound, _i, _j, _k, _l, _len, _len1, _ref, _ref1, _ref2, _results;
      this.interpolatedBeats = [];
      lowerBound = this.distanceToTime(this._maxEnergyDistance - MAX_SEARCH_WINDOW_SIZE);
      upperBound = this.distanceToTime(this._maxEnergyDistance + MAX_SEARCH_WINDOW_SIZE);
      meanLength = this.distanceToTime(this._maxEnergyDistance);
      beatsToInsert = [];
      for (i = _i = 0, _ref = this.beats.length - 2; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        beat = this.beats[i];
        nextBeat = this.beats[i + 1];
        gap = nextBeat - beat;
        if (gap >= lowerBound && gap <= upperBound) {
          continue;
        }
        subdivisions = gap / meanLength;
        if (subdivisions < 1) {
          subdivisions = 2;
        }
        newBeats = [];
        numberOfNewBeats = Math.round(subdivisions);
        for (j = _j = 1; 1 <= numberOfNewBeats ? _j <= numberOfNewBeats : _j >= numberOfNewBeats; j = 1 <= numberOfNewBeats ? ++_j : --_j) {
          newTime = beat + (gap / numberOfNewBeats) * j;
          if (nextBeat - lowerBound < newTime) {
            continue;
          }
          newBeats.push(newTime);
        }
        beatsToInsert.push({
          index: i + 1,
          beats: newBeats
        });
      }
      numberOfNewBeatsInserted = 0;
      for (_k = 0, _len = beatsToInsert.length; _k < _len; _k++) {
        b = beatsToInsert[_k];
        (_ref1 = this.beats).splice.apply(_ref1, [b.index + numberOfNewBeatsInserted, 0].concat(__slice.call(b.beats)));
        _ref2 = b.beats;
        for (_l = 0, _len1 = _ref2.length; _l < _len1; _l++) {
          beat = _ref2[_l];
          this.interpolatedBeats.push(beat);
        }
        numberOfNewBeatsInserted += b.beats.length;
      }
      nextTime = this.beats[0] - meanLength;
      while (nextTime > 0) {
        this.beats.splice(0, 0, nextTime);
        this.interpolatedBeats.splice(0, 0, nextTime);
        nextTime -= meanLength;
      }
      nextTime = this.beats[this.beats.length - 1] + meanLength;
      _results = [];
      while (nextTime < this._trackLength) {
        this.beats.push(nextTime);
        this.interpolatedBeats.push(nextTime);
        _results.push(nextTime += meanLength);
      }
      return _results;
    };

    return BeatDetector;

  })();

  main = function() {
    return self.addEventListener('message', function(event) {
      var beatDetector, data, pcmData;
      data = event.data;
      pcmData = data.pcmData;
      beatDetector = new BeatDetector();
      beatDetector.detectBeats(data.pcmData, data.previousEnergyVarianceCoefficient, data.previousAverageEnergyCoefficient, data.samplesPerInstantEnergy, data.numberOfPreviousSamples, data.maxBpm, data.sampleRate);
      return self.postMessage({
        bpm: beatDetector.bpm,
        principalBeatTime: beatDetector.principalBeatTime,
        maxEnergy: beatDetector.maxEnergy,
        energies: beatDetector.energies,
        averageEnergies: beatDetector.averageEnergies,
        beats: beatDetector.beats,
        interpolatedBeats: beatDetector.interpolatedBeats,
        maximumEnergies: beatDetector.maximumEnergies
      });
    });
  };

  main();

}).call(this);
