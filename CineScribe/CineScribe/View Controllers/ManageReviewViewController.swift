//
//  ManageReviewViewController.swift
//  CineScribe
//
//  Created by Marlon Raskin on 9/24/19.
//  Copyright © 2019 Marlon Raskin. All rights reserved.
//

import UIKit

protocol ManageReviewVCDelegate {
	func setMovieToReview(movie: Movie)
}

enum ManageReviewType {
	case new
	case newWithMovie(Movie)
	case existing(Review)
}

class ManageReviewViewController: UIViewController {
	
	// MARK: - IBOutlets
	
	 @IBOutlet private weak var titleBtn: UIButton!
	 @IBOutlet private weak var quotesBtn: UIButton!
	 @IBOutlet private weak var sceneNotesBtn: UIButton!
	 @IBOutlet private weak var actorNotesBtn: UIButton!
	 @IBOutlet private weak var cinemaNotesBtn: UIButton!
	 @IBOutlet private weak var titleTextField: UITextField!
	 @IBOutlet private weak var quotesTextView: UITextView!
	 @IBOutlet private weak var sceneNotesTextView: UITextView!
	 @IBOutlet private weak var actorNotesTextView: UITextView!
	 @IBOutlet private weak var cinemaNotesTextView: UITextView!
	 @IBOutlet private weak var saveBtn: UIBarButtonItem!
	 @IBOutlet private weak var movieBtn: UIBarButtonItem!
	
	// MARK: - Properties
	
	private var textBtns = [UIButton]()
	private var textViews = [UITextView]()
	var reviewDelegate: ManageReviewVCDelegate? // should be weak (swiftlint gives a warning)
	var firebaseClient: FirebaseClient?
	var currentcollectionId: UUID?
	var reviewType = ManageReviewType.new
	private var movieId: Int {
		switch reviewType {
		case .newWithMovie(let movie):
			return movie.id
		case .existing(let review):
			if let id = review.movieId {
                return id
            }
			fallthrough
		default:
			return 0
		}
	}
	private var movie: Movie? {
		if case let ManageReviewType.newWithMovie(movie) = reviewType {
			return movie
		}
		return nil
	}
	private var review: Review? {
		if case let ManageReviewType.existing(review) = reviewType {
			return review
		}
		return nil
	}
	
	// MARK: - Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		reviewDelegate = self
		
		textBtns = [titleBtn, quotesBtn, sceneNotesBtn, actorNotesBtn, cinemaNotesBtn]
		textViews = [quotesTextView, sceneNotesTextView, actorNotesTextView, cinemaNotesTextView]
		
		setupViews()
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let navController = segue.destination as? UINavigationController, let movieSearchVC = navController.children.first as? ReviewMovieSearchTableViewController {
			movieSearchVC.reviewDelegate = reviewDelegate
		}
	}
	
	//MARK: - IBActions
	
    @IBAction func saveBtnTapped(_ sender: Any) {
        guard let collectionId = currentcollectionId, let title = titleTextField.optionalText else { return }

        firebaseClient?.putReview(collectionId: collectionId,
                                  reviewId: review?.id,
                                  title: title,
                                  movie: movie,
                                  memorableQuotes: quotesTextView.text,
                                  sceneDescription: sceneNotesTextView.text,
                                  actorNotes: actorNotesTextView.text,
                                  cinematographyNotes: cinemaNotesTextView.text,
                                  completion: {
            print("Review Saved!")
            self.dismiss(animated: true, completion: nil)
        })
    }
	
	@IBAction func movieBtnTapped(_ sender: Any) {
        guard let searchVC = UIStoryboard(name: "Search", bundle: nil).instantiateInitialViewController() as? DiscoverViewController else { return }
		
		present(searchVC, animated: true, completion: nil)
	}
	
	@IBAction func collapsableBtnTapped(_ sender: UIButton) {
		switch sender.tag {
		case 0:
			titleTextField.isHidden.toggle()
		case 1:
			quotesTextView.isHidden.toggle()
		case 2:
			sceneNotesTextView.isHidden.toggle()
		case 3:
			actorNotesTextView.isHidden.toggle()
		case 4:
			cinemaNotesTextView.isHidden.toggle()
		default:
			break
		}
	}
	
	// MARK: - Helpers
	
	private func setupViews() {
		titleTextField.tag = 0
		
		for index in 0..<textBtns.count {
			textBtns[index].tag = index
		}
		
		for index in 0..<textViews.count {
			textViews[index].tag = index + 1
		}
		
		for index in 0..<textViews.count {
			if review == nil {
				textViews[index].isHidden = true
				textViews[index].text = ""
			}
			textViews[index].layer.borderWidth = 2
			textViews[index].layer.borderColor = UIColor.lightGray.cgColor
			textViews[index].layer.cornerRadius = 10
			textViews[index].layer.masksToBounds = true
		}
		
		titleTextField.becomeFirstResponder()
		
		switch reviewType {
		case .newWithMovie(let movie):
			if movie.id > 0 {
				navigationItem.rightBarButtonItem?.title = "Open Movie"
			} else {
				navigationItem.rightBarButtonItem = nil
			}
		case .existing(let review):
			title = "Review"
			titleTextField.text = review.title
			quotesTextView.text = review.memorableQuotes
			sceneNotesTextView.text = review.sceneDescription
			actorNotesTextView.text = review.actorNotes
			cinemaNotesTextView.text = review.cinematographyNotes
		default:
			break
		}
	}
}

extension ManageReviewViewController: ManageReviewVCDelegate {
	func setMovieToReview(movie: Movie) {
		reviewType = .newWithMovie(movie)
		navigationItem.rightBarButtonItems = nil
	}
}
