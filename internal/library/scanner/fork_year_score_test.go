package scanner

import (
	"seanime/internal/library/anime"
	"testing"

	"github.com/stretchr/testify/assert"
)

func mediaStarting(year int) *anime.NormalizedMedia {
	return &anime.NormalizedMedia{StartDate: &anime.NormalizedMediaDate{Year: &year}}
}

func TestCalculateYearScore_LaterSeasonWithPremiereYear(t *testing.T) {
	// "A Couple of Cuckoos (2022) - S02E01": premiere year vs the 2025 sequel entry
	assert.Equal(t, 0.0, calculateYearScore(2022, 2, mediaStarting(2025), 8))
	// Detective Conan (1996) - S09E..: one long-running entry that started in 1996
	assert.Equal(t, scoreYearExactMatch, calculateYearScore(1996, 9, mediaStarting(1996), 8))
}

func TestCalculateYearScore_UnchangedOtherwise(t *testing.T) {
	// no season / season 1: mismatch still penalised
	assert.Equal(t, scoreYearMismatch, calculateYearScore(2022, -1, mediaStarting(2025), 8))
	assert.Equal(t, scoreYearMismatch, calculateYearScore(2022, 1, mediaStarting(2025), 8))
	// later season but the file's year is newer than the entry: still a mismatch
	assert.Equal(t, scoreYearMismatch, calculateYearScore(2025, 2, mediaStarting(2022), 8))
}
